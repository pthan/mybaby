import 'package:sqflite/sqflite.dart';

import '../../domain/models/daily_water.dart';
import '../../domain/utils/date_key.dart';
import '../db/app_database.dart';

class WaterRepository {
  WaterRepository(this._db);

  final AppDatabase _db;

  Future<DailyWater> fetchToday() async {
    final key = todayKey();
    final db = await _db.database;
    final rows = await db.query('daily_water', where: 'date = ?', whereArgs: [key], limit: 1);
    if (rows.isNotEmpty) return DailyWater.fromMap(rows.first);
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('daily_water', {
      'date': key,
      'total_ml': 0,
      'created_at': now,
      'updated_at': now,
    });
    return DailyWater(id: id, date: key, totalMl: 0, createdAt: now, updatedAt: now);
  }

  Future<List<Map<String, dynamic>>> recentLog({int limit = 5}) async {
    final key = todayKey();
    final db = await _db.database;
    return db.query('water_log', where: 'date = ?', whereArgs: [key], orderBy: 'time DESC', limit: limit);
  }

  Future<DailyWater> addWater(int amount) async {
    final key = todayKey();
    final db = await _db.database;
    final nowIso = DateTime.now().toIso8601String();
    await fetchToday();
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE daily_water SET total_ml = total_ml + ?, updated_at = ? WHERE date = ?',
        [amount, nowIso, key],
      );
      await txn.insert('water_log', {'date': key, 'time': nowIso, 'amount_ml': amount});
    });
    return fetchToday();
  }
}
