import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite entry point. Handles creation and migration.
class AppDatabase {
  static const _dbName = 'mybaby.db';
  static const _dbVersion = 5;

  Database? _cachedDb;

  Future<Database> get database async {
    if (_cachedDb != null) return _cachedDb!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _cachedDb = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE daily_feast_summary ADD COLUMN total_milk_sessions INTEGER NOT NULL DEFAULT 0;');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE daily_feast_summary ADD COLUMN reminder_at TEXT;');
          await db.execute('ALTER TABLE daily_feast_summary ADD COLUMN last_feeding_time TEXT;');
          await db.execute('ALTER TABLE daily_feast_summary ADD COLUMN alarm_enable INTEGER NOT NULL DEFAULT 1;');
          await db.execute(
            'UPDATE daily_feast_summary SET last_feeding_time = last_feast_end_time WHERE last_feast_end_time IS NOT NULL AND last_feeding_time IS NULL;',
          );
        }
        if (oldVersion < 4) {
          await db.rawUpdate("UPDATE control_policy SET remind_hr = ? WHERE type = 'feast_milk';", [2 / 60]);
        }
        if (oldVersion < 5) {
          await db.rawUpdate("UPDATE control_policy SET remind_hr = ? WHERE type = 'feast_milk';", [2.0]);
        }
      },
    );
    return _cachedDb!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE control_policy (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        remind_hr REAL NOT NULL,
        value_category TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE daily_excretory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        pee_count INTEGER NOT NULL DEFAULT 0,
        last_pee_time TEXT,
        poop_count INTEGER NOT NULL DEFAULT 0,
        last_poop_time TEXT,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE excretory_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        type TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE daily_feast (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration_sec INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE daily_feast_summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        total_feast_time_sec INTEGER NOT NULL DEFAULT 0,
        total_milk_sessions INTEGER NOT NULL DEFAULT 0,
        total_pee INTEGER NOT NULL DEFAULT 0,
        total_pooh INTEGER NOT NULL DEFAULT 0,
        alarm_enable INTEGER NOT NULL DEFAULT 1,
        reminder_at TEXT,
        last_feeding_time TEXT,
        last_feast_end_time TEXT,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE daily_water (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        total_ml INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE water_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        amount_ml INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE reminder_schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        next_trigger_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('control_policy', {
      'type': 'water_drink',
      'value': 3.0,
      'remind_hr': 1.0,
      'value_category': 'liter',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('control_policy', {
      'type': 'feast_milk',
      'value': 2.0,
      'remind_hr': 2.0, // default to 2 hours between feeds
      'value_category': 'hr',
      'created_at': now,
      'updated_at': now,
    });
  }
}
