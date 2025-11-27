import 'package:sqflite/sqflite.dart';

import '../../domain/models/daily_excretory.dart';
import '../../domain/models/daily_feast_summary.dart';
import '../../domain/utils/date_key.dart';
import '../db/app_database.dart';

class ExcretoryRepository {
  ExcretoryRepository(this._db);

  final AppDatabase _db;

  Future<DailyExcretory> fetchToday() async {
    final key = todayKey();
    final db = await _db.database;
    final rows = await db.query('daily_excretory', where: 'date = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) {
      final now = DateTime.now().toIso8601String();
    final id = await db.insert('daily_excretory', {
      'date': key,
      'pee_count': 0,
      'poop_count': 0,
      'created_at': now,
      'updated_at': now,
    });
    await _ensureSummary(db, key);
    return DailyExcretory(
      id: id,
        date: key,
        peeCount: 0,
        poopCount: 0,
        lastPeeTime: null,
        lastPoopTime: null,
        createdAt: now,
        updatedAt: now,
      );
    }
    return DailyExcretory.fromMap(rows.first);
  }

  Future<DailyFeastSummary> _ensureSummary(DatabaseExecutor db, String date) async {
    final rows = await db.query('daily_feast_summary', where: 'date = ?', whereArgs: [date], limit: 1);
    if (rows.isNotEmpty) return DailyFeastSummary.fromMap(rows.first);
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('daily_feast_summary', {
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
    return DailyFeastSummary(
      id: id,
      date: date,
      totalFeastTimeSec: 0,
      totalMilkSessions: 0,
      totalPee: 0,
      totalPooh: 0,
      totalDiaper: 0,
      alarmEnable: true,
      reminderAt: null,
      lastFeedingTime: null,
      createdAt: now,
      updatedAt: now,
      lastFeastEndTime: null,
    );
  }

  Future<List<DateTime>> fetchLogsToday(String type) async {
    final key = todayKey();
    final db = await _db.database;
    await fetchToday(); // ensures row exists for today
    final rows = await db.query(
      'excretory_log',
      where: 'date = ? AND type = ?',
      whereArgs: [key, type],
      orderBy: 'time DESC',
    );
    return rows
        .map((row) => DateTime.tryParse(row['time'] as String))
        .whereType<DateTime>()
        .toList();
  }

  Future<DailyExcretory> incrementPee() async {
    final key = todayKey();
    final db = await _db.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    await fetchToday(); // ensures row exists
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE daily_excretory SET pee_count = pee_count + 1, last_pee_time = ?, updated_at = ? WHERE date = ?',
        [nowIso, nowIso, key],
      );
      await _ensureSummary(txn, key);
      await txn.rawUpdate(
        'UPDATE daily_feast_summary SET total_pee = total_pee + 1, updated_at = ? WHERE date = ?',
        [nowIso, key],
      );
      await txn.insert('excretory_log', {'date': key, 'time': nowIso, 'type': 'pee'});
    });
    return fetchToday();
  }

  Future<DailyExcretory> incrementPoop() async {
    final key = todayKey();
    final db = await _db.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    await fetchToday();
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE daily_excretory SET poop_count = poop_count + 1, last_poop_time = ?, updated_at = ? WHERE date = ?',
        [nowIso, nowIso, key],
      );
      await _ensureSummary(txn, key);
      await txn.rawUpdate(
        'UPDATE daily_feast_summary SET total_pooh = total_pooh + 1, updated_at = ? WHERE date = ?',
        [nowIso, key],
      );
      await txn.insert('excretory_log', {'date': key, 'time': nowIso, 'type': 'poop'});
    });
    return fetchToday();
  }

  Future<DailyExcretory> decrementPee() async {
    final key = todayKey();
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE daily_excretory SET pee_count = CASE WHEN pee_count > 0 THEN pee_count - 1 ELSE 0 END, updated_at = ? WHERE date = ?',
        [nowIso, key],
      );
      await _ensureSummary(txn, key);
      await txn.rawUpdate(
        'UPDATE daily_feast_summary SET total_pee = CASE WHEN total_pee > 0 THEN total_pee - 1 ELSE 0 END, updated_at = ? WHERE date = ?',
        [nowIso, key],
      );
    });
    return fetchToday();
  }

  Future<DailyExcretory> decrementPoop() async {
    final key = todayKey();
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE daily_excretory SET poop_count = CASE WHEN poop_count > 0 THEN poop_count - 1 ELSE 0 END, updated_at = ? WHERE date = ?',
        [nowIso, key],
      );
      await _ensureSummary(txn, key);
      await txn.rawUpdate(
        'UPDATE daily_feast_summary SET total_pooh = CASE WHEN total_pooh > 0 THEN total_pooh - 1 ELSE 0 END, updated_at = ? WHERE date = ?',
        [nowIso, key],
      );
    });
    return fetchToday();
  }

  Future<DailyExcretory> removeLog(DateTime time, String type) async {
    final key = todayKey();
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final deleted = await txn.delete(
        'excretory_log',
        where: 'date = ? AND time = ? AND type = ?',
        whereArgs: [key, time.toIso8601String(), type],
      );
      if (deleted == 0) return;

      if (type == 'pee') {
        final latest = await txn.query(
          'excretory_log',
          columns: ['time'],
          where: 'date = ? AND type = ?',
          whereArgs: [key, 'pee'],
          orderBy: 'time DESC',
          limit: 1,
        );
        final latestTime = latest.isNotEmpty ? latest.first['time'] as String? : null;
        await txn.rawUpdate(
          'UPDATE daily_excretory SET pee_count = CASE WHEN pee_count > 0 THEN pee_count - 1 ELSE 0 END, last_pee_time = ?, updated_at = ? WHERE date = ?',
          [latestTime, nowIso, key],
        );
        await _ensureSummary(txn, key);
        await txn.rawUpdate(
          'UPDATE daily_feast_summary SET total_pee = CASE WHEN total_pee > 0 THEN total_pee - 1 ELSE 0 END, updated_at = ? WHERE date = ?',
          [nowIso, key],
        );
      } else if (type == 'poop') {
        final latest = await txn.query(
          'excretory_log',
          columns: ['time'],
          where: 'date = ? AND type = ?',
          whereArgs: [key, 'poop'],
          orderBy: 'time DESC',
          limit: 1,
        );
        final latestTime = latest.isNotEmpty ? latest.first['time'] as String? : null;
        await txn.rawUpdate(
          'UPDATE daily_excretory SET poop_count = CASE WHEN poop_count > 0 THEN poop_count - 1 ELSE 0 END, last_poop_time = ?, updated_at = ? WHERE date = ?',
          [latestTime, nowIso, key],
        );
        await _ensureSummary(txn, key);
        await txn.rawUpdate(
          'UPDATE daily_feast_summary SET total_pooh = CASE WHEN total_pooh > 0 THEN total_pooh - 1 ELSE 0 END, updated_at = ? WHERE date = ?',
          [nowIso, key],
        );
      }
    });
    return fetchToday();
  }
}
