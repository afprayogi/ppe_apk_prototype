import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/employee_model.dart';
import 'database_helper.dart';

class EmployeeDao {
  static const _table = 'employees';

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ── Write ────────────────────────────────────────────────────────────────

  Future<void> insert(EmployeeModel emp) async {
    final db = await _db;
    await db.insert(
      _table,
      _toMap(emp),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(EmployeeModel emp) async {
    final db = await _db;
    await db.update(
      _table,
      _toMap(emp),
      where: 'id = ?',
      whereArgs: [emp.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<EmployeeModel>> fetchAll() async {
    final db   = await _db;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(_fromMap).toList();
  }

  Future<EmployeeModel?> fetchById(String id) async {
    final db   = await _db;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  Future<List<EmployeeModel>> search(String query) async {
    final db   = await _db;
    final like = '%${query.toLowerCase()}%';
    final rows = await db.rawQuery(
      'SELECT * FROM $_table WHERE LOWER(name) LIKE ? OR nia LIKE ?',
      [like, like],
    );
    return rows.map(_fromMap).toList();
  }

  Future<int> count() async {
    final db     = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toMap(EmployeeModel e) => {
        'id':           e.id,
        'name':         e.name,
        'nia':          e.nia,
        'address':      e.address,
        'shift':        e.shift,
        'required_ppe': jsonEncode(e.requiredPpe),
        'avatar_path':  e.avatarUrl,
        'created_at':   DateTime.now().millisecondsSinceEpoch,
      };

  EmployeeModel _fromMap(Map<String, dynamic> row) => EmployeeModel(
        id:          row['id'] as String,
        name:        row['name'] as String,
        nia:         row['nia'] as String,
        address:     row['address'] as String,
        shift:       row['shift'] as String,
        requiredPpe: List<String>.from(
            jsonDecode(row['required_ppe'] as String) as List),
        avatarUrl:   row['avatar_path'] as String?,
      );
}
