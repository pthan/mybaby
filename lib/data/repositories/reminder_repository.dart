import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Future<void> setNextTrigger(String type, DateTime next) async {
    final db = await _db.database;
    await db.insert(
      'reminder_schedule',
      {'type': type, 'next_trigger_at': next.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getNextTrigger(String type) async {
    final db = await _db.database;
    final rows = await db.query('reminder_schedule', where: 'type = ?', whereArgs: [type], limit: 1);
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['next_trigger_at'] as String);
  }
}
