<p align="center">
  <img src="assets/brand/app_icon.png" width="120" alt="GearGuard logo" />
</p>

<h1 align="center">GearGuard</h1>

<p align="center">
  <b>PPE compliance scanning, attendance and safety reporting for the workplace.</b><br/>
  A production-style Flutter app: clean architecture, a custom design system, light &amp; dark themes, and PDF reporting.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white" />
  <img alt="State" src="https://img.shields.io/badge/state-flutter__bloc-FF6B00" />
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-Android%20%C2%B7%20iOS%20%C2%B7%20Web%20%C2%B7%20Windows%20%C2%B7%20macOS-lightgrey" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
</p>

---

## Overview

Before a worker steps onto a job site, a supervisor needs to know one thing: **are they wearing the right protective equipment?**

GearGuard turns that check into a few taps. Scan a worker, see exactly which items (helmet, vest, gloves, boots, goggles, mask) were detected and with what confidence, log the result, and roll everything up into attendance views, rankings and audit-ready PDF reports.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/01-onboarding.png" width="200" /><br/><sub>Onboarding</sub></td>
    <td align="center"><img src="docs/screenshots/02-dashboard.png" width="200" /><br/><sub>Home · dark</sub></td>
    <td align="center"><img src="docs/screenshots/02-dashboard-light.png" width="200" /><br/><sub>Home · light</sub></td>
    <td align="center"><img src="docs/screenshots/03-scan.png" width="200" /><br/><sub>Scan</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/04-scan-result.png" width="200" /><br/><sub>Scan result</sub></td>
    <td align="center"><img src="docs/screenshots/05-attendance.png" width="200" /><br/><sub>Attendance</sub></td>
    <td align="center"><img src="docs/screenshots/06-team-ranking.png" width="200" /><br/><sub>Team ranking</sub></td>
    <td align="center"><img src="docs/screenshots/07-archive.png" width="200" /><br/><sub>Archive</sub></td>
  </tr>
</table>

## Features

| Area | Highlights |
| --- | --- |
| **Home** | Live compliance ring for today, checked-in / violations / pending counters, 7-day trend, most-missed equipment, recent scans |
| **Scan** | Pick a worker, run a scan, see bounding boxes and a per-item confidence checklist, save or discard |
| **Attendance** | Day-by-day check-in list with PPE status per person; one tap to scan whoever hasn't checked in |
| **Team** | Add and search employees, per-person history and compliance, compliance **ranking** |
| **Archive** | Every scan grouped by day, filter by result, search by employee, detail view, delete |
| **PDF reports** | Branded report for one scan, one person, or the whole filtered archive — share or print |
| **Settings** | Required equipment, confidence threshold, violation alerts, site & supervisor, light / dark / auto theme, demo data |

## Detection: demo mode, real interface

The scanner runs against a **simulated detector** so the entire app can be explored without a camera or a trained model. Results are randomised, and the Scan screen says so ("Demo detector").

Detection lives behind one small interface, so a real on-device model (for example YOLO via a platform channel) plugs in without touching any screen:

```dart
abstract interface class PpeDetector {
  /// Confidence (0–1) for every [PpeItem] in the current frame.
  Future<Map<PpeItem, double>> detect();
}
```

```dart
runApp(App(prefs: prefs, detector: MyYoloDetector()));
```

## Architecture

```
lib/
├── app/        MaterialApp, dependency wiring, onboarding gate
├── core/       theme, formatters, shared widgets (logo, rings, charts, pills)
├── domain/     PpeItem, Employee, ScanRecord — pure Dart, JSON-serialisable
├── data/       PpeDetector, SafetyRepository (local storage), PDF report builder
├── cubits/     SafetyCubit, SettingsCubit, NavCubit (flutter_bloc)
└── features/   dashboard · scanner · attendance · employees · archive · settings · onboarding
```

- **State management:** `flutter_bloc` cubits with immutable states; derived values (compliance rate, ranking, miss counts) live on the state, not in widgets.
- **Persistence:** JSON in `shared_preferences`, which works on every platform including web.
- **Swappable seams:** detector injected through `RepositoryProvider`; storage hidden behind `SafetyRepository`.
- **Design system:** Material 3, safety-orange brand on deep slate, complete light and dark themes. Logo, compliance rings, weekly chart and detection overlay are custom-painted — no charting dependency.
- **Accessibility:** semantic labels on tappable cards, tooltips on icon buttons, and status is never conveyed by colour alone (every pill has an icon and text).

## Getting started

Requirements: Flutter 3.41+ (Dart 3.11+).

```sh
git clone <this-repo>
cd gearguard
flutter pub get
```

Run it:

```sh
# Web
flutter run -d chrome --target lib/main_production.dart

# Android / iOS (flavors: development, staging, production)
flutter run --flavor development --target lib/main_development.dart
```

Quality checks:

```sh
flutter analyze
flutter test
```

Regenerate the README screenshots (renders the real screens with the SDK's Roboto and Material Icons fonts):

```sh
flutter test tool/screenshots_test.dart --update-goldens
```

## Tests

```sh
flutter test                      # 38 tests
flutter test --coverage && python tool/eval/coverage_summary.py
```

| What | Result |
| --- | --- |
| Automated tests (unit, state, PDF, persistence, end-to-end widget) | **38 pass** |
| Line coverage | **75.1 %** (domain 100 %, data 95 %, core 92 %, state 80 %, screens 67 %) |
| Accessibility guidelines (tap target, labelled target, WCAG text contrast; 5 screens × light/dark) | **20 pass** — 3 failed at first (contrast as low as 2.13:1), fixed by darkening the light primary to `#A83600` |
| `flutter analyze` | 0 errors, 0 warnings |

## Detector smoke test

The author's earlier YOLOv8/TFLite model ([release `model`](https://github.com/afprayogi/ppe_apk_prototype/releases/tag/model), 6.2 MB) was run on the 11 validation photos of the prototype with `tool/eval/eval_yolo_tflite.py`:

| Class | n | Detected | Mean conf. (app resize) | Mean conf. (letterbox) |
| --- | --- | --- | --- | --- |
| helmet | 5 | 5/5 | 0.89 | 0.89 |
| Vest | 3 | 3/3 | 0.79 | 0.86 |
| safety_shoe | 3 | 3/3 | 0.64 | 0.82 |
| **All** | 11 | **11/11** | 0.80 | 0.87 |

Mean latency 79.7 ms/frame on a desktop AMD Ryzen CPU (LiteRT, 4 threads; 242.6 ms on 1 thread, 70.2 ms on 8). **Caveat:** tiny, positive-only, weakly labelled (class from file name) — a functional check, not an accuracy benchmark; goggles/gloves/mask were not exercised. More experiments (`tool/eval/experiments.py`, results in [`docs/eval`](docs/eval)):

| Experiment | Finding |
| --- | --- |
| Threshold sweep | Letterbox keeps 11/11 up to τ = 0.7; the app's direct resize drops to 9/11 at τ = 0.6 → use letterbox |
| Robustness (10 perturbations) | Insensitive to darkening, JPEG, ±15° rotation, noise, 4× down-scaling; **weak to occlusion (5/11 with a 25 % patch)** and heavy blur (8/11) |
| Negative images (15) | 2 false positives, both *Vest* on plain orange/pink patches → colour bias toward hi-vis hues |

Raw results: [`docs/eval`](docs/eval). The Flutter app itself still uses the simulated detector until this model is wired behind `PpeDetector`.

## Research paper

A 4-page IEEE-style paper (compliance model, architecture, detector experiments, software verification): [English PDF](docs/paper/GearGuard-paper-en.pdf) · [PDF Bahasa Indonesia](docs/paper/GearGuard-paper-id.pdf) · [LaTeX source](docs/paper/main.tex). Every number in it is produced by a script in [`tool/eval`](tool/eval). It makes **no accuracy claim and no usability claim**: the labelled-benchmark and user study are still to do (see [`docs/paper/README.md`](docs/paper/README.md)).

## Background

GearGuard is a from-scratch redesign of the earlier
[`ppe_apk_prototype`](https://github.com/afprayogi/ppe_apk_prototype), keeping the same product scope (scanner, employees, attendance, archive, PDF export, settings) with a new architecture, design system and brand.

## Roadmap

- [ ] Real camera preview and on-device YOLO detector behind `PpeDetector`
- [ ] SQLite storage for large histories
- [ ] Per-department reports and CSV export
- [ ] Localisation (Bahasa Indonesia)

## Tech stack

Flutter · Dart · flutter_bloc · shared_preferences · pdf · printing

## License

Released under the [MIT License](LICENSE).
