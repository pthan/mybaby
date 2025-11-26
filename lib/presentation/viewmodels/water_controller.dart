import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/policy_repository.dart';
import '../../data/repositories/water_repository.dart';
import '../../domain/models/control_policy.dart';
import '../../domain/models/daily_water.dart';
import '../../services/reminder_service.dart';

class WaterState {
  WaterState({
    required this.loading,
    required this.water,
    required this.policy,
    required this.log,
  });

  final bool loading;
  final DailyWater? water;
  final ControlPolicy? policy;
  final List<Map<String, dynamic>> log;

  WaterState copyWith({
    bool? loading,
    DailyWater? water,
    ControlPolicy? policy,
    List<Map<String, dynamic>>? log,
  }) {
    return WaterState(
      loading: loading ?? this.loading,
      water: water ?? this.water,
      policy: policy ?? this.policy,
      log: log ?? this.log,
    );
  }

  static WaterState initial() => WaterState(
        loading: true,
        water: null,
        policy: null,
        log: const [],
      );
}

class WaterController extends StateNotifier<WaterState> {
  WaterController(this._repo, this._policyRepo, this._reminderService) : super(WaterState.initial());

  final WaterRepository _repo;
  final PolicyRepository _policyRepo;
  final ReminderService _reminderService;

  Future<void> load() async {
    final water = await _repo.fetchToday();
    final log = await _repo.recentLog(limit: 5);
    final policy = await _policyRepo.getByType('water_drink');
    state = state.copyWith(loading: false, water: water, log: log, policy: policy);
    await _scheduleIfNeeded();
  }

  Future<void> addWater(int amount) async {
    final updated = await _repo.addWater(amount);
    final log = await _repo.recentLog(limit: 5);
    state = state.copyWith(water: updated, log: log);
    await _scheduleIfNeeded();
  }

  Future<void> refreshPolicy() async {
    final policy = await _policyRepo.getByType('water_drink');
    state = state.copyWith(policy: policy);
    await _scheduleIfNeeded();
  }

  Future<void> _scheduleIfNeeded() async {
    final targetMl = ((state.policy?.value ?? 0) * 1000).round();
    final total = state.water?.totalMl ?? 0;
    final remindHr = state.policy?.remindHr ?? 1.0;
    if (targetMl == 0) return;
    if (total >= targetMl) {
      await _reminderService.cancelWaterReminder();
      return;
    }
    final delay = Duration(minutes: (remindHr * 60).round());
    await _reminderService.scheduleWaterReminder(delay);
  }
}
