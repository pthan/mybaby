import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
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
    final excel = ex.Excel.createExcel();
    final tables = _allTables;

    for (final table in tables) {
      final rows = await db.query(table);
      final sheet = excel[table];
      if (rows.isEmpty) {
        sheet.appendRow([ex.TextCellValue('-- empty --')]);
        continue;
      }
      final headers = rows.first.keys.toList();
      sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());
      for (final row in rows) {
        sheet.appendRow(headers.map((h) => _toCellValue(row[h])).toList());
      }
    }

    final targetDir = await _downloadsDir();
    final name = fileName != null && fileName.trim().isNotEmpty
        ? fileName.trim()
        : 'mybaby_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.xlsx';
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
    final excel = ex.Excel.decodeBytes(bytes);
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final table in _allTables) {
        final sheet = excel.tables[table];
        if (sheet == null || sheet.rows.isEmpty) continue;
        final rows = sheet.rows;
        final headerRow = rows.first;
        final headers = headerRow
            .map((cell) => _unwrapCellValue(_rawCellValue(cell))?.toString() ?? '')
            .toList();
        await txn.delete(table);
        for (final row in rows.skip(1)) {
          final data = <String, Object?>{};
          for (var i = 0; i < headers.length && i < row.length; i++) {
            final key = headers[i];
            if (key.isEmpty) continue;
            data[key] = _toDbValue(_unwrapCellValue(_rawCellValue(row[i])));
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
        'setting',
        'diaper_status',
      ];

  ex.CellValue? _toCellValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return ex.IntCellValue(value);
    if (value is num) return ex.DoubleCellValue(value.toDouble());
    if (value is bool) return ex.BoolCellValue(value);
    if (value is DateTime) return ex.DateCellValue.fromDateTime(value);
    return ex.TextCellValue(value.toString());
  }

  dynamic _rawCellValue(dynamic cell) {
    if (cell is ex.Data) return cell.value;
    return cell;
  }

  dynamic _unwrapCellValue(dynamic value) {
    if (value is String || value is num || value is bool || value is DateTime) return value;
    if (value is ex.IntCellValue) return value.value;
    if (value is ex.DoubleCellValue) return value.value;
    if (value is ex.BoolCellValue) return value.value;
    if (value is ex.TextCellValue) return value.value;
    if (value is ex.DateCellValue) return value.asDateTimeLocal();
    if (value is ex.TextSpan) return value.toString();
    return value?.toString();
  }

  Object? _toDbValue(dynamic value) {
    if (value == null) return null;
    if (value is num || value is String || value is bool || value is Uint8List) return value;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}
