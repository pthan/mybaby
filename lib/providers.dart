import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db/app_database.dart';
import 'data/repositories/excretory_repository.dart';
import 'data/repositories/feast_repository.dart';
import 'data/repositories/policy_repository.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/water_repository.dart';
import 'presentation/viewmodels/policy_controller.dart';
import 'presentation/viewmodels/backup_controller.dart';
import 'presentation/viewmodels/today_summary_controller.dart';
import 'presentation/viewmodels/water_controller.dart';
import 'services/backup_service.dart';
import 'services/reminder_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db);
});

final backupControllerProvider = StateNotifierProvider<BackupController, BackupState>((ref) {
  return BackupController(ref.watch(backupServiceProvider));
});

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PolicyRepository(db);
});

final excretoryRepositoryProvider = Provider<ExcretoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExcretoryRepository(db);
});

final feastRepositoryProvider = Provider<FeastRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FeastRepository(db);
});

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WaterRepository(db);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReminderRepository(db);
});

final reminderServiceProvider = Provider<ReminderService>((ref) => throw UnimplementedError('Override in main'));

final todaySummaryControllerProvider = StateNotifierProvider<TodaySummaryController, TodaySummaryState>((ref) {
  return TodaySummaryController(
    ref.watch(excretoryRepositoryProvider),
    ref.watch(feastRepositoryProvider),
    ref.watch(policyRepositoryProvider),
    ref.watch(reminderRepositoryProvider),
    ref.watch(reminderServiceProvider),
  )..load();
});

final waterControllerProvider = StateNotifierProvider<WaterController, WaterState>((ref) {
  return WaterController(
    ref.watch(waterRepositoryProvider),
    ref.watch(policyRepositoryProvider),
    ref.watch(reminderServiceProvider),
  )..load();
});

final policyControllerProvider = StateNotifierProvider<PolicyController, PolicyState>((ref) {
  return PolicyController(
    ref.watch(policyRepositoryProvider),
    onMilkPolicyChanged: () => ref.read(todaySummaryControllerProvider.notifier).refreshPolicy(),
    onWaterPolicyChanged: () => ref.read(waterControllerProvider.notifier).refreshPolicy(),
  )..load();
});
