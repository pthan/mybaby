import 'package:sqflite/sqflite.dart';

import '../../domain/models/control_policy.dart';
import '../db/app_database.dart';

class PolicyRepository {
  PolicyRepository(this._db);

  final AppDatabase _db;

  Future<ControlPolicy> getByType(String type) async {
    final db = await _db.database;
    final rows = await db.query('control_policy', where: 'type = ?', whereArgs: [type], limit: 1);
    if (rows.isEmpty) {
      throw StateError('Policy not found for $type');
    }
    return ControlPolicy.fromMap(rows.first);
  }

  Future<void> updateValue(String type, double value, double remindHr) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'control_policy',
      {
        'value': value,
        'remind_hr': remindHr,
        'updated_at': now,
      },
      where: 'type = ?',
      whereArgs: [type],
    );
  }
}
