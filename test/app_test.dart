import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearguard/app/app.dart';
import 'package:gearguard/data/ppe_detector.dart';
import 'package:gearguard/data/safety_repository.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/domain/scan_record.dart';
import 'package:gearguard/features/onboarding/onboarding_page.dart';
import 'package:gearguard/features/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDetector implements PpeDetector {
  @override
  Future<Map<PpeItem, double>> detect() async => {
    for (final i in PpeItem.values) i: i == PpeItem.gloves ? 0.1 : 0.95,
  };
}

Future<void> _pump(WidgetTester tester, {bool onboarded = true}) async {
  tester.view
    ..physicalSize = const Size(900, 2400)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'settings.onboardingDone': onboarded,
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(App(prefs: prefs, detector: _FakeDetector()));
  await tester.pumpAndSettle();
}

void main() {
  group('domain', () {
    test('ScanRecord computes compliance and survives JSON', () {
      final record = ScanRecord(
        id: '1',
        employeeId: 'e',
        time: DateTime(2026, 1, 1, 8),
        scores: const {PpeItem.helmet: 0.9, PpeItem.vest: 0.4},
        required: const [PpeItem.helmet, PpeItem.vest],
        threshold: 0.6,
      );
      expect(record.compliant, isFalse);
      expect(record.missing, [PpeItem.vest]);
      expect(record.score, 0.5);

      final copy = ScanRecord.fromJson(record.toJson());
      expect(copy.missing, [PpeItem.vest]);
      expect(copy.time, record.time);
    });

    test('demo data is deterministic and non-empty', () {
      final a = SafetyRepository.demoData(now: DateTime(2026, 5, 20));
      final b = SafetyRepository.demoData(now: DateTime(2026, 5, 20));
      expect(a.employees, hasLength(8));
      expect(a.scans, isNotEmpty);
      expect(a.scans.length, b.scans.length);
    });

    test('simulated detector scores every item within 0..1', () {
      final scores = SimulatedDetector.generate(Random(1));
      expect(scores.keys.toSet(), PpeItem.values.toSet());
      expect(scores.values.every((v) => v >= 0 && v <= 1), isTrue);
    });
  });

  group('app', () {
    testWidgets('first launch shows onboarding, then the shell', (t) async {
      await _pump(t, onboarded: false);
      expect(find.byType(OnboardingPage), findsOneWidget);
      await t.tap(find.text('Skip'));
      await t.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('scan flow saves a violation to the archive', (t) async {
      await _pump(t);
      await t.tap(find.text('Scan').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Start scan').last);
      await t.pump(const Duration(milliseconds: 100));
      await t.pumpAndSettle();
      expect(find.text('PPE violation'), findsOneWidget);
      expect(find.textContaining('Gloves'), findsWidgets);

      await t.ensureVisible(find.text('Save to archive'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save to archive'));
      await t.pumpAndSettle();
      expect(find.textContaining('is missing Gloves'), findsOneWidget);
    });

    testWidgets('team tab lists demo employees and can add one', (t) async {
      await _pump(t);
      await t.tap(find.text('Team'));
      await t.pumpAndSettle();
      expect(find.text('Budi Santoso'), findsOneWidget);

      await t.tap(find.text('Add'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'Test Worker');
      await t.tap(find.text('Save employee'));
      await t.pumpAndSettle();
      expect(find.text('Test Worker'), findsOneWidget);
    });

    testWidgets('archive filters violations', (t) async {
      await _pump(t);
      await t.tap(find.text('Archive'));
      await t.pumpAndSettle();
      await t.tap(find.text('Violations'));
      await t.pumpAndSettle();
      expect(find.text('Compliant'), findsOneWidget); // segment label only
      expect(find.text('Violation'), findsWidgets);
    });
  });
}
