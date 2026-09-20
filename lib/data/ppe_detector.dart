import 'dart:math';

import 'package:gearguard/domain/ppe_item.dart';

/// Turns a camera frame into per-item confidence scores.
///
/// The app talks to this interface only, so a real on-device model
/// (e.g. YOLO through a platform channel) can replace [SimulatedDetector]
/// without touching any UI code.
// ignore: one_member_abstracts
abstract interface class PpeDetector {
  Future<Map<PpeItem, double>> detect();
}

/// Demo detector: produces plausible, randomised results after a short delay.
class SimulatedDetector implements PpeDetector {
  SimulatedDetector({Random? random, this.wearRate = 0.8})
    : _random = random ?? Random();

  final Random _random;

  /// Probability that any given item is being worn.
  final double wearRate;

  @override
  Future<Map<PpeItem, double>> detect() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    return generate(_random, wearRate: wearRate);
  }

  static Map<PpeItem, double> generate(Random random, {double wearRate = 0.8}) {
    return {
      for (final item in PpeItem.values)
        item: random.nextDouble() < wearRate
            ? 0.62 + random.nextDouble() * 0.36
            : random.nextDouble() * 0.35,
    };
  }
}
