import 'package:flutter/foundation.dart';

@immutable
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    department: json['department'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
  );

  final String id;
  final String name;

  /// Employee number, e.g. `EMP-014`.
  final String code;
  final String department;
  final DateTime createdAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'department': department,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
