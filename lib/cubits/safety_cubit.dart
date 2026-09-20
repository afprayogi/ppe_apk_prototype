import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:gearguard/data/safety_repository.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/ppe_item.dart';
import 'package:gearguard/domain/scan_record.dart';

@immutable
class SafetyState {
  const SafetyState({this.employees = const [], this.scans = const []});

  final List<Employee> employees;

  /// All scans, newest first.
  final List<ScanRecord> scans;

  Employee? employee(String id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<ScanRecord> scansOn(DateTime day) => [
    for (final s in scans)
      if (DateUtils.isSameDay(s.time, day)) s,
  ];

  List<ScanRecord> scansFor(String employeeId) => [
    for (final s in scans)
      if (s.employeeId == employeeId) s,
  ];

  /// Latest scan for an employee on [day], if any.
  ScanRecord? checkIn(String employeeId, DateTime day) {
    for (final s in scans) {
      if (s.employeeId == employeeId && DateUtils.isSameDay(s.time, day)) {
        return s;
      }
    }
    return null;
  }

  /// Fraction (0–1) of scans on [day] that were fully compliant, or `null`.
  double? complianceOn(DateTime day) {
    final list = scansOn(day);
    if (list.isEmpty) return null;
    return list.where((s) => s.compliant).length / list.length;
  }

  double? complianceOf(String employeeId) {
    final list = scansFor(employeeId);
    if (list.isEmpty) return null;
    return list.where((s) => s.compliant).length / list.length;
  }

  /// Average equipment score for an employee, 0–1.
  double averageScoreOf(String employeeId) {
    final list = scansFor(employeeId);
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (a, s) => a + s.score) / list.length;
  }

  /// Employees ranked by compliance, best first. Unscanned people go last.
  List<Employee> get ranking {
    final list = [...employees]
      ..sort((a, b) {
        final ca = complianceOf(a.id) ?? -1;
        final cb = complianceOf(b.id) ?? -1;
        final byCompliance = cb.compareTo(ca);
        if (byCompliance != 0) return byCompliance;
        return averageScoreOf(b.id).compareTo(averageScoreOf(a.id));
      });
    return list;
  }

  /// Which equipment is missed most often (item → miss count).
  Map<PpeItem, int> get missCounts {
    final counts = <PpeItem, int>{};
    for (final s in scans) {
      for (final m in s.missing) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    return counts;
  }
}

class SafetyCubit extends Cubit<SafetyState> {
  SafetyCubit(this._repository) : super(const SafetyState()) {
    _init();
  }

  final SafetyRepository _repository;

  void _init() {
    if (!_repository.hasStoredData) {
      final demo = SafetyRepository.demoData();
      _sortAndEmit(demo.employees, demo.scans);
      unawaited(_persist());
      return;
    }
    _sortAndEmit(_repository.loadEmployees(), _repository.loadScans());
  }

  void _sortAndEmit(List<Employee> employees, List<ScanRecord> scans) {
    emit(
      SafetyState(
        employees: employees,
        scans: [...scans]..sort((a, b) => b.time.compareTo(a.time)),
      ),
    );
  }

  Future<void> _persist() async {
    await _repository.saveEmployees(state.employees);
    await _repository.saveScans(state.scans);
  }

  Future<Employee> addEmployee({
    required String name,
    required String department,
    String? code,
  }) async {
    final next = state.employees.length + 1;
    final employee = Employee(
      id: 'emp-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      code: (code?.trim().isNotEmpty ?? false)
          ? code!.trim().toUpperCase()
          : 'EMP-${next.toString().padLeft(3, '0')}',
      department: department.trim(),
      createdAt: DateTime.now(),
    );
    _sortAndEmit([...state.employees, employee], state.scans);
    await _persist();
    return employee;
  }

  Future<void> deleteEmployee(String id) async {
    _sortAndEmit(
      [
        for (final e in state.employees)
          if (e.id != id) e,
      ],
      [
        for (final s in state.scans)
          if (s.employeeId != id) s,
      ],
    );
    await _persist();
  }

  Future<ScanRecord> recordScan({
    required String employeeId,
    required Map<PpeItem, double> scores,
    required List<PpeItem> required,
    required double threshold,
  }) async {
    final record = ScanRecord(
      id: 'scan-${DateTime.now().microsecondsSinceEpoch}',
      employeeId: employeeId,
      time: DateTime.now(),
      scores: scores,
      required: required,
      threshold: threshold,
    );
    _sortAndEmit(state.employees, [record, ...state.scans]);
    await _persist();
    return record;
  }

  Future<void> deleteScan(String id) async {
    _sortAndEmit(state.employees, [
      for (final s in state.scans)
        if (s.id != id) s,
    ]);
    await _persist();
  }

  Future<void> clearScans() async {
    _sortAndEmit(state.employees, const []);
    await _persist();
  }

  Future<void> resetDemoData() async {
    final demo = SafetyRepository.demoData();
    _sortAndEmit(demo.employees, demo.scans);
    await _persist();
  }
}
