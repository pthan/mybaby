import 'package:sqflite/sqflite.dart';

import '../../domain/models/daily_feast.dart';
import '../../domain/models/daily_feast_summary.dart';
import '../../domain/utils/date_key.dart';
import '../db/app_database.dart';

class FeastRepository {
  FeastRepository(this._db);

  static const _unset = Object();

  final AppDatabase _db;

  Future<DailyFeastSummary> fetchSummaryToday() async {
    final key = todayKey();
    final db = await _db.database;
    final rows = await db.query('daily_feast_summary', where: 'date = ?', whereArgs: [key], limit: 1);
    if (rows.isNotEmpty) return DailyFeastSummary.fromMap(rows.first);
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('daily_feast_summary', {
      'date': key,
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
      date: key,
      totalFeastTimeSec: 0,
      totalMilkSessions: 0,
      totalPee: 0,
      totalPooh: 0,
      totalDiaper: 0,
      alarmEnable: true,
      reminderAt: null,
      lastFeedingTime: null,
      lastFeastEndTime: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<DailyFeast>> sessionsToday() async {
    final key = todayKey();
    final db = await _db.database;
    final rows = await db.query('daily_feast', where: 'date = ?', whereArgs: [key], orderBy: 'start_time DESC');
    return rows.map(DailyFeast.fromMap).toList();
  }

  Future<DailyFeastSummary> addSession(
    DateTime start,
    DateTime end, {
    DateTime? nextReminder,
    bool? alarmEnabled,
  }) async {
    final key = todayKey();
    final db = await _db.database;
    final durationSec = end.difference(start).inSeconds;
    final nowIso = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('daily_feast', {
        'date': key,
        'type': 'baby_milk_feast',
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'duration_sec': durationSec,
      });
      await _ensureSummary(txn, key);
      await txn.rawUpdate(
        '''
        UPDATE daily_feast_summary SET 
          total_feast_time_sec = total_feast_time_sec + ?, 
          total_milk_sessions = total_milk_sessions + 1, 
          last_feast_end_time = ?, 
          last_feeding_time = ?, 
          reminder_at = ?,
          alarm_enable = COALESCE(?, alarm_enable),
          updated_at = ?
        WHERE date = ?
        ''',
        [
          durationSec,
          end.toIso8601String(),
          end.toIso8601String(),
          nextReminder?.toIso8601String(),
          alarmEnabled != null ? (alarmEnabled ? 1 : 0) : null,
          nowIso,
          key
        ],
      );
    });
    return fetchSummaryToday();
  }

  Future<List<DailyFeastSummary>> fetchRecentSummaries({int days = 7}) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_feast_summary',
      orderBy: 'date DESC',
      limit: days,
    );
    return rows.map(DailyFeastSummary.fromMap).toList();
  }

  Future<DailyFeastSummary> saveReminderFields({
    Object? reminderAt = _unset,
    Object? lastFeedingTime = _unset,
    bool? alarmEnabled,
  }) async {
    final key = todayKey();
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await _ensureSummary(db, key);
    final data = <String, Object?>{'updated_at': nowIso};
    if (!identical(reminderAt, _unset)) {
      data['reminder_at'] = (reminderAt as DateTime?)?.toIso8601String();
    }
    if (!identical(lastFeedingTime, _unset)) {
      final iso = (lastFeedingTime as DateTime?)?.toIso8601String();
      data['last_feeding_time'] = iso;
      if (iso != null) {
        data['last_feast_end_time'] = iso;
      }
    }
    if (alarmEnabled != null) {
      data['alarm_enable'] = alarmEnabled ? 1 : 0;
    }
    await db.update('daily_feast_summary', data, where: 'date = ?', whereArgs: [key]);
    return fetchSummaryToday();
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
      lastFeastEndTime: null,
      createdAt: now,
      updatedAt: now,
    );
  }
}
