// Renders the README screenshots into docs/screenshots.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// Uses the real Roboto + Material Icons fonts from the Flutter SDK so the
// output looks like the running app rather than test placeholder boxes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearguard/app/app.dart';
import 'package:gearguard/data/ppe_detector.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Detector implements PpeDetector {
  @override
  Future<Map<PpeItem, double>> detect() async => {
        PpeItem.helmet: 0.94,
        PpeItem.vest: 0.31,
        PpeItem.gloves: 0.88,
        PpeItem.boots: 0.91,
        PpeItem.goggles: 0.9,
        PpeItem.mask: 0.9,
      };
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('$dir/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

void main() {
  setUpAll(_loadFonts);

  Future<void> boot(
    WidgetTester t, {
    bool onboarded = true,
    Brightness brightness = Brightness.dark,
  }) async {
    t.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    t.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(() {
      t.view.reset();
      t.platformDispatcher.clearAllTestValues();
    });
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': onboarded,
    });
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(App(prefs: prefs, detector: _Detector()));
    await t.pumpAndSettle();
  }

  Future<void> shot(WidgetTester t, String name) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../docs/screenshots/$name.png'),
      );

  testWidgets('onboarding', (t) async {
    await boot(t, onboarded: false);
    await shot(t, '01-onboarding');
  });

  testWidgets('dashboard dark + light', (t) async {
    await boot(t);
    await shot(t, '02-dashboard');
    await boot(t, brightness: Brightness.light);
    await shot(t, '02-dashboard-light');
  });

  testWidgets('scan', (t) async {
    await boot(t);
    await t.tap(find.text('Scan').first);
    await t.pumpAndSettle();
    await shot(t, '03-scan');
    await t.tap(find.text('Start scan').last);
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
    await shot(t, '04-scan-result');
  });

  testWidgets('attendance, team, archive', (t) async {
    await boot(t);
    await t.tap(find.text('Attendance'));
    await t.pumpAndSettle();
    await shot(t, '05-attendance');
    await t.tap(find.text('Team'));
    await t.pumpAndSettle();
    await t.tap(find.text('Ranking'));
    await t.pumpAndSettle();
    await shot(t, '06-team-ranking');
    await t.tap(find.text('Archive'));
    await t.pumpAndSettle();
    await shot(t, '07-archive');
  });
}
