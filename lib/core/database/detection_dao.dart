import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/detection_model.dart';
import 'database_helper.dart';

class DetectionDao {
  static const _table = 'detection_records';

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ── Write ────────────────────────────────────────────────────────────────

  Future<void> insert(DetectionRecord rec) async {
    final db = await _db;
    await db.insert(
      _table,
      _toMap(rec),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(_table);
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<DetectionRecord>> fetchAll({int limit = 50}) async {
    final db   = await _db;
    final rows = await db.query(
      _table,
      orderBy: 'detected_at DESC',
      limit:   limit,
    );
    return rows.map(_fromMap).toList();
  }

  Future<List<DetectionRecord>> fetchByEmployee(String employeeId) async {
    final db   = await _db;
    final rows = await db.query(
      _table,
      where:     'employee_id = ?',
      whereArgs: [employeeId],
      orderBy:   'detected_at DESC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<List<DetectionRecord>> fetchByDate(DateTime date) async {
    final db    = await _db;
    final start = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final end   = DateTime(date.year, date.month, date.day, 23, 59, 59)
        .millisecondsSinceEpoch;
    final rows  = await db.query(
      _table,
      where:     'detected_at BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy:   'detected_at DESC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<int> countNonSafetyToday() async {
    final db    = await _db;
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;
    final result = await db.rawQuery(
      "SELECT COUNT(*) FROM $_table WHERE detected_at >= ? AND missing_ppe != '[]'",
      [start],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns count per day for the last [days] days – used for trend chart.
  Future<List<Map<String, dynamic>>> trendByDay(int days) async {
    final db    = await _db;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    return db.rawQuery('''
      SELECT
        date(detected_at / 1000, 'unixepoch') AS day,
        COUNT(*) AS total
      FROM $_table
      WHERE detected_at >= ?
      GROUP BY day
      ORDER BY day ASC
    ''', [since]);
  }

  /// Top non-compliant employees grouped by a PPE item.
  Future<List<Map<String, dynamic>>> rankByMissingPpe(
      String ppeItem, int limit) async {
    final db     = await _db;
    final filter = ppeItem == 'ALL' ? '' : "AND missing_ppe LIKE '%$ppeItem%'";
    return db.rawQuery('''
      SELECT
        employee_name,
        nia,
        COUNT(*) AS score
      FROM $_table
      WHERE missing_ppe != '[]' $filter
      GROUP BY employee_id
      ORDER BY score DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Hitung berapa kali tiap item APD hilang — untuk pie chart
  Future<Map<String, int>> missingPpeStats() async {
    final db      = await _db;
    final rows    = await db.query(_table,
        columns: ['missing_ppe'],
        where: "missing_ppe != '[]'");
    final counts  = <String, int>{};
    for (final row in rows) {
      final list = List<String>.from(
          jsonDecode(row['missing_ppe'] as String) as List);
      for (final item in list) {
        counts[item] = (counts[item] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Total deteksi complete vs non-complete
  Future<Map<String, int>> completionStats() async {
    final db = await _db;
    final total    = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_table')) ?? 0;
    final complete = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM $_table WHERE missing_ppe = '[]'")) ?? 0;
    return {'complete': complete, 'incomplete': total - complete};
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toMap(DetectionRecord r) => {
        'id':            r.id,
        'employee_id':   r.employeeId,
        'employee_name': r.employeeName,
        'nia':           r.nia,
        'detected_at':   r.detectedAt.millisecondsSinceEpoch,
        'detected_ppe':  jsonEncode(r.detectedPpe),
        'missing_ppe':   jsonEncode(r.missingPpe),
        'status':        r.status.name,
        'confidence':    r.overallConfidence,
        'image_path':    r.imageUrl,
      };

  DetectionRecord _fromMap(Map<String, dynamic> row) => DetectionRecord(
        id:               row['id'] as String,
        employeeId:       row['employee_id'] as String,
        employeeName:     row['employee_name'] as String,
        nia:              row['nia'] as String,
        detectedAt:       DateTime.fromMillisecondsSinceEpoch(
            row['detected_at'] as int),
        detectedPpe:      List<String>.from(
            jsonDecode(row['detected_ppe'] as String) as List),
        missingPpe:       List<String>.from(
            jsonDecode(row['missing_ppe'] as String) as List),
        status:           row['status'] == 'complete'
            ? DetectionStatus.complete
            : DetectionStatus.progress,
        overallConfidence: (row['confidence'] as num).toDouble(),
        imageUrl:         row['image_path'] as String?,
      );
}
