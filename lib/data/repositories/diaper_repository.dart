import 'package:sqflite/sqflite.dart';

import '../../domain/models/diaper_status.dart';
import '../../domain/utils/date_key.dart';
import '../db/app_database.dart';

class DiaperRepository {
  DiaperRepository(this._db);

  final AppDatabase _db;

  Future<DiaperStatus> fetchStatus() async {
    final db = await _db.database;
    await db.insert(
      'diaper_status',
      {'id': 1, 'active': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    final rows = await db.query('diaper_status', where: 'id = 1', limit: 1);
    if (rows.isEmpty) {
      return DiaperStatus(active: false);
    }
    return DiaperStatus.fromMap(rows.first);
  }

  Future<DiaperStatus> startSession(DateTime start, Duration remindAfter) async {
    final db = await _db.database;
    final next = start.add(remindAfter).toIso8601String();
    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'diaper_status',
      {
        'active': 1,
        'active_start_time': start.toIso8601String(),
        'next_change_at': next,
        'change_at': null,
        'updated_at': nowIso,
      },
      where: 'id = 1',
    );
    return fetchStatus();
  }

  Future<DiaperStatus> stopSession() async {
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'diaper_status',
      {
        'active': 0,
        'active_start_time': null,
        'next_change_at': null,
        'change_at': nowIso,
        'updated_at': nowIso,
      },
      where: 'id = 1',
    );
    return fetchStatus();
  }

  Future<DiaperStatus> finishChange(DateTime finishedAt) async {
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    final key = todayKey();
    await _ensureSummary(db, key);
    await db.update(
      'diaper_status',
      {
        'active': 0,
        'next_change_at': null,
        'change_at': finishedAt.toIso8601String(),
        'updated_at': nowIso,
      },
      where: 'id = 1',
    );
    await _incrementTotalDiaper(db, key, nowIso);
    return fetchStatus();
  }

  Future<DiaperStatus> updateNextChange(DateTime next) async {
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'diaper_status',
      {
        'next_change_at': next.toIso8601String(),
        'active': 1,
        'updated_at': nowIso,
      },
      where: 'id = 1',
    );
    return fetchStatus();
  }

  Future<void> _ensureSummary(DatabaseExecutor db, String date) async {
    final rows = await db.query('daily_feast_summary', where: 'date = ?', whereArgs: [date], limit: 1);
    if (rows.isNotEmpty) return;
    final now = DateTime.now().toIso8601String();
    await db.insert('daily_feast_summary', {
      'date': date,
      'total_feast_time_sec': 0,
      'total_milk_sessions': 0,
      'total_pee': 0,
      'total_pooh': 0,
      'total_diaper': 0,
      'alarm_enable': 1,
      'reminder_at': null,
      'last_feeding_time': null,
      'last_feast_end_time': null,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _incrementTotalDiaper(DatabaseExecutor db, String date, String updatedAt) async {
    final rows = await db.query('daily_feast_summary', columns: ['id'], where: 'date = ?', whereArgs: [date], limit: 1);
    if (rows.isEmpty) {
      await _ensureSummary(db, date);
    }
    await db.rawUpdate(
      'UPDATE daily_feast_summary SET total_diaper = total_diaper + 1, updated_at = ? WHERE date = ?',
      [updatedAt, date],
    );
  }
}
