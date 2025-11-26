import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/db/app_database.dart';

/// Handles full-database import/export to an Excel workbook.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Exports all known tables into separate sheets and returns the saved file path.
  Future<String> exportAll({String? fileName}) async {
    final db = await _db.database;
    final excel = Excel.createExcel();
    final tables = _allTables;

    for (final table in tables) {
      final rows = await db.query(table);
      final sheet = excel[table];
      if (rows.isEmpty) {
        sheet.appendRow([TextCellValue('-- empty --')]);
        continue;
      }
      final headers = rows.first.keys.toList();
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (final row in rows) {
        sheet.appendRow(headers.map((h) => _toCellValue(row[h])).toList());
      }
    }

    final targetDir = await _downloadsDir();
    final name = fileName != null && fileName.trim().isNotEmpty ? fileName.trim() : 'mybaby_backup.xlsx';
    final safeName = name.endsWith('.xlsx') ? name : '$name.xlsx';
    final filePath = p.join(targetDir.path, safeName);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode workbook');
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Imports data from an Excel workbook created by [exportAll].
  Future<void> importAll(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at $filePath');
    }
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final table in _allTables) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.rows.isEmpty) continue;
        final rows = sheet.rows;
        final headers = rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
        await txn.delete(table);
        for (final row in rows.skip(1)) {
          final data = <String, Object?>{};
          for (var i = 0; i < headers.length && i < row.length; i++) {
            final key = headers[i];
            if (key.isEmpty) continue;
            data[key] = row[i]?.value;
          }
          if (data.isEmpty) continue;
          await txn.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<Directory> _downloadsDir() async {
    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) return publicDownloads;
    }
    final dir = await getDownloadsDirectory();
    if (dir != null) return dir;
    return await getApplicationDocumentsDirectory();
  }

  List<String> get _allTables => const [
        'control_policy',
        'daily_excretory',
        'excretory_log',
        'daily_feast',
        'daily_feast_summary',
        'daily_water',
        'water_log',
        'reminder_schedule',
      ];

  CellValue? _toCellValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return IntCellValue(value);
    if (value is num) return DoubleCellValue(value.toDouble());
    if (value is bool) return BoolCellValue(value);
    if (value is DateTime) return DateCellValue.fromDateTime(value);
    return TextCellValue(value.toString());
  }
}
