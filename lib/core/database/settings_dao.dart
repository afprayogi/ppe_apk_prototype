import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsDao {
  static const _table = 'settings';

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<String?> get(String key) async {
    final db   = await _db;
    final rows = await db.query(_table, where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await _db;
    await db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> getAll() async {
    final db   = await _db;
    final rows = await db.query(_table);
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }
}
