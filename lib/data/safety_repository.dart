import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' show DateUtils;
import 'package:gearguard/data/ppe_detector.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/domain/scan_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for employees and scan history (JSON in preferences).
class SafetyRepository {
  SafetyRepository(this._prefs);

  static const _employeesKey = 'safety.employees.v1';
  static const _scansKey = 'safety.scans.v1';

  final SharedPreferences _prefs;

  bool get hasStoredData => _prefs.containsKey(_employeesKey);

  List<Employee> loadEmployees() => _decode(_employeesKey, Employee.fromJson);
  List<ScanRecord> loadScans() => _decode(_scansKey, ScanRecord.fromJson);

  Future<void> saveEmployees(List<Employee> employees) => _prefs.setString(
    _employeesKey,
    jsonEncode([for (final e in employees) e.toJson()]),
  );

  Future<void> saveScans(List<ScanRecord> scans) => _prefs.setString(
    _scansKey,
    jsonEncode([for (final s in scans) s.toJson()]),
  );

  List<T> _decode<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<dynamic>)
          fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  /// Demo dataset: a small crew with a week of scan history.
  static ({List<Employee> employees, List<ScanRecord> scans}) demoData({
    DateTime? now,
    int seed = 42,
  }) {
    final random = Random(seed);
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    const crew = [
      ('Budi Santoso', 'Construction', 0.95),
      ('Siti Rahmawati', 'Welding', 0.9),
      ('Agus Wijaya', 'Logistics', 0.7),
      ('Dewi Lestari', 'Maintenance', 0.92),
      ('Rizky Pratama', 'Construction', 0.6),
      ('Ayu Kartika', 'Welding', 0.85),
      ('Hendra Gunawan', 'Logistics', 0.78),
      ('Maya Anggraini', 'Maintenance', 0.88),
    ];

    final employees = <Employee>[
      for (var i = 0; i < crew.length; i++)
        Employee(
          id: 'emp-${i + 1}',
          name: crew[i].$1,
          code: 'EMP-${(i + 1).toString().padLeft(3, '0')}',
          department: crew[i].$2,
          createdAt: today.subtract(Duration(days: 90 - i * 7)),
        ),
    ];

    final scans = <ScanRecord>[];
    for (var d = 6; d >= 0; d--) {
      final day = today.subtract(Duration(days: d));
      for (var i = 0; i < employees.length; i++) {
        // Most people check in; a few skip a day. Today is only partly done.
        final skip = random.nextDouble() < 0.1;
        final notYet = d == 0 && random.nextDouble() < 0.35;
        if (skip || notYet) continue;
        scans.add(
          ScanRecord(
            id: 'seed-$d-$i',
            employeeId: employees[i].id,
            time: day.add(
              Duration(hours: 6, minutes: 30 + random.nextInt(90)),
            ),
            scores: SimulatedDetector.generate(random, wearRate: crew[i].$3),
            required: PpeItem.defaults.toList(),
            threshold: 0.6,
          ),
        );
      }
    }
    return (employees: employees, scans: scans);
  }
}
