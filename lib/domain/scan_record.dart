import 'package:flutter/foundation.dart';
import 'package:gearguard/domain/ppe_item.dart';

/// The outcome of one PPE scan for one employee.
@immutable
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.employeeId,
    required this.time,
    required this.scores,
    required this.required,
    required this.threshold,
  });

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    PpeItem? byName(String n) {
      for (final i in PpeItem.values) {
        if (i.name == n) return i;
      }
      return null;
    }

    final scores = <PpeItem, double>{};
    (json['scores'] as Map<String, dynamic>).forEach((k, v) {
      final item = byName(k);
      if (item != null) scores[item] = (v as num).toDouble();
    });
    return ScanRecord(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
      scores: scores,
      required: [
        for (final n in json['required'] as List<dynamic>)
          if (byName(n as String) != null) byName(n)!,
      ],
      threshold: (json['threshold'] as num).toDouble(),
    );
  }

  final String id;
  final String employeeId;
  final DateTime time;

  /// Detector confidence (0–1) for every item.
  final Map<PpeItem, double> scores;

  /// Equipment that was required when the scan was taken.
  final List<PpeItem> required;

  /// Minimum confidence for an item to count as detected.
  final double threshold;

  bool isDetected(PpeItem item) => (scores[item] ?? 0) >= threshold;

  List<PpeItem> get missing =>
      required.where((i) => !isDetected(i)).toList(growable: false);

  bool get compliant => missing.isEmpty;

  /// Share of required equipment that was worn (0–1).
  double get score => required.isEmpty
      ? 1
      : (required.length - missing.length) / required.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'time': time.millisecondsSinceEpoch,
    'scores': {for (final e in scores.entries) e.key.name: e.value},
    'required': [for (final i in required) i.name],
    'threshold': threshold,
  };
}
