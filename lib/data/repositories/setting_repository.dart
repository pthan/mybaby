import 'package:sqflite/sqflite.dart';

import '../../domain/models/setting.dart';
import '../db/app_database.dart';

class SettingRepository {
  SettingRepository(this._db);

  final AppDatabase _db;

  Future<List<Setting>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query('setting', orderBy: 'settingname ASC');
    return rows.map(Setting.fromMap).toList();
  }

  Future<Setting?> getByName(String name) async {
    final db = await _db.database;
    final rows = await db.query('setting', where: 'settingname = ?', whereArgs: [name], limit: 1);
    if (rows.isEmpty) return null;
    return Setting.fromMap(rows.first);
  }

  Future<void> updateEnable(String name, bool enable) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'setting',
      {'enable': enable ? 1 : 0, 'updated_at': now},
      where: 'settingname = ?',
      whereArgs: [name],
    );
  }
}
