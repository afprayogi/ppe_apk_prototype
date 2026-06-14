import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Singleton that owns the SQLite connection.
/// Call [DatabaseHelper.instance.database] to get the DB.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path   = p.join(dbPath, 'vivatpass.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        nia         TEXT NOT NULL UNIQUE,
        address     TEXT NOT NULL,
        shift       TEXT NOT NULL,
        required_ppe TEXT NOT NULL,   -- JSON array string
        avatar_path TEXT,
        created_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE detection_records (
        id            TEXT PRIMARY KEY,
        employee_id   TEXT NOT NULL,
        employee_name TEXT NOT NULL,
        nia           TEXT NOT NULL,
        detected_at   INTEGER NOT NULL,
        detected_ppe  TEXT NOT NULL,  -- JSON array string
        missing_ppe   TEXT NOT NULL,  -- JSON array string
        status        TEXT NOT NULL,
        confidence    REAL NOT NULL,
        image_path    TEXT,
        FOREIGN KEY (employee_id) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default settings
    await db.insert('settings', {'key': 'location', 'value': 'Surabaya'});
    await db.insert('settings', {'key': 'shift_active', 'value': 'Shift 1'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration steps here when version increments
  }

  /// Delete & re-create – useful during development
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, 'vivatpass.db'));
    _db = null;
  }
}
