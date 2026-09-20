import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearguard/app/app.dart';
import 'package:gearguard/cubits/safety_cubit.dart';
import 'package:gearguard/cubits/settings_cubit.dart';
import 'package:gearguard/data/report_pdf.dart';
import 'package:gearguard/data/safety_repository.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/domain/scan_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScanRecord _scan(String id, String emp, Map<PpeItem, double> scores) =>
    ScanRecord(
      id: id,
      employeeId: emp,
      time: DateTime(2026, 5, 20, 8),
      scores: scores,
      required: const [PpeItem.helmet, PpeItem.vest],
      threshold: 0.6,
    );

void main() {
  group('compliance model', () {
    test('score is the share of required items worn', () {
      final s = _scan('1', 'a', {PpeItem.helmet: 0.9, PpeItem.vest: 0.1});
      expect(s.score, 0.5);
      expect(_scan('2', 'a', {PpeItem.helmet: 1, PpeItem.vest: 1}).score, 1);
      expect(_scan('3', 'a', {}).score, 0);
    });

    test('threshold is inclusive (c >= tau counts as detected)', () {
      final s = _scan('1', 'a', {PpeItem.helmet: 0.6, PpeItem.vest: 0.59});
      expect(s.isDetected(PpeItem.helmet), isTrue);
      expect(s.isDetected(PpeItem.vest), isFalse);
    });

    test('compliant <=> no missing items, for every score combination', () {
      for (final h in [0.0, 0.59, 0.6, 1.0]) {
        for (final v in [0.0, 0.59, 0.6, 1.0]) {
          final s = _scan('x', 'a', {PpeItem.helmet: h, PpeItem.vest: v});
          expect(s.compliant, s.missing.isEmpty);
          expect(s.compliant, h >= 0.6 && v >= 0.6);
        }
      }
    });

    test('JSON round-trip preserves the rules used at scan time', () {
      final s = _scan('1', 'a', {PpeItem.helmet: 0.7, PpeItem.vest: 0.2});
      final copy = ScanRecord.fromJson(s.toJson());
      expect(copy.threshold, 0.6);
      expect(copy.required, s.required);
      expect(copy.compliant, s.compliant);
    });
  });

  group('state', () {
    Future<SafetyCubit> cubit() async {
      SharedPreferences.setMockInitialValues({});
      return SafetyCubit(
        SafetyRepository(await SharedPreferences.getInstance()),
      );
    }

    test('ranking is sorted by compliance rate, best first', () async {
      final c = await cubit();
      final rates = [
        for (final e in c.state.ranking) c.state.complianceOf(e.id) ?? -1,
      ];
      final sorted = [...rates]..sort((a, b) => b.compareTo(a));
      expect(rates, sorted);
    });

    test('deleting an employee also removes their scans', () async {
      final c = await cubit();
      final victim = c.state.employees.first.id;
      expect(c.state.scansFor(victim), isNotEmpty);
      await c.deleteEmployee(victim);
      expect(c.state.scansFor(victim), isEmpty);
      expect(c.state.employee(victim), isNull);
    });

    test('state survives a restart (persistence)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = SafetyCubit(SafetyRepository(prefs));
      await first.addEmployee(name: 'Persist Me', department: 'Ops');
      final second = SafetyCubit(SafetyRepository(prefs));
      expect(second.state.employees.map((e) => e.name), contains('Persist Me'));
      expect(second.state.scans.length, first.state.scans.length);
    });

    test('at least one PPE item always stays required', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsCubit(await SharedPreferences.getInstance());
      for (final i in PpeItem.values) {
        await s.toggleRequired(i);
      }
      expect(s.state.required, isNotEmpty);
    });

    test('threshold is clamped', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsCubit(await SharedPreferences.getInstance());
      await s.setThreshold(5);
      expect(s.state.threshold, lessThanOrEqualTo(0.95));
      await s.setThreshold(-1);
      expect(s.state.threshold, greaterThanOrEqualTo(0.3));
    });
  });

  group('pdf report', () {
    test('produces a valid, non-trivial PDF', () async {
      final demo = SafetyRepository.demoData(now: DateTime(2026, 5, 20));
      final bytes = await buildReportPdf(
        siteName: 'Test Site',
        supervisor: 'Tester',
        scans: demo.scans,
        employeeOf: (id) {
          for (final e in demo.employees) {
            if (e.id == id) return e;
          }
          return null;
        },
        generatedAt: DateTime(2026, 5, 21),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(2000));
    });

    test('an empty archive still yields a PDF', () async {
      final bytes = await buildReportPdf(
        siteName: 'S',
        supervisor: 'T',
        scans: const [],
        employeeOf: (_) => null,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('accessibility (Flutter guideline checks)', () {
    Future<void> boot(WidgetTester t, Brightness b) async {
      t.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      t.platformDispatcher.platformBrightnessTestValue = b;
      addTearDown(() {
        t.view.reset();
        t.platformDispatcher.clearAllTestValues();
      });
      SharedPreferences.setMockInitialValues({
        'settings.onboardingDone': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(App(prefs: prefs));
      await t.pumpAndSettle();
    }

    for (final b in [Brightness.light, Brightness.dark]) {
      for (final tab in ['Home', 'Attendance', 'Scan', 'Team', 'Archive']) {
        testWidgets('$tab · ${b.name}: tap targets and labels', (t) async {
          final handle = t.ensureSemantics();
          await boot(t, b);
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          await expectLater(t, meetsGuideline(androidTapTargetGuideline));
          await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });

        testWidgets('$tab · ${b.name}: text contrast', (t) async {
          final handle = t.ensureSemantics();
          await boot(t, b);
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          await expectLater(t, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  });
}
