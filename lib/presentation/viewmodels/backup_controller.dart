import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backup_service.dart';

class BackupState {
  const BackupState({
    this.exporting = false,
    this.importing = false,
    this.lastExportPath,
    this.message,
    this.error,
  });

  final bool exporting;
  final bool importing;
  final String? lastExportPath;
  final String? message;
  final String? error;

  BackupState copyWith({
    bool? exporting,
    bool? importing,
    String? lastExportPath,
    String? message,
    String? error,
  }) {
    return BackupState(
      exporting: exporting ?? this.exporting,
      importing: importing ?? this.importing,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      message: message,
      error: error,
    );
  }
}

class BackupController extends StateNotifier<BackupState> {
  BackupController(this._service) : super(const BackupState());

  final BackupService _service;

  Future<void> exportAll(String? fileName) async {
    state = state.copyWith(exporting: true, message: null, error: null);
    try {
      final path = await _service.exportAll(fileName: fileName);
      state = state.copyWith(
        exporting: false,
        lastExportPath: path,
        message: 'Exported to $path',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(exporting: false, error: e.toString());
    }
  }

  Future<void> importAll(String filePath) async {
    if (filePath.trim().isEmpty) {
      state = state.copyWith(error: 'Please provide a file path to import');
      return;
    }
    state = state.copyWith(importing: true, message: null, error: null);
    try {
      await _service.importAll(filePath);
      state = state.copyWith(importing: false, message: 'Imported data from $filePath', error: null);
    } catch (e) {
      state = state.copyWith(importing: false, error: e.toString());
    }
  }
}
