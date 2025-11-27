import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/diaper_repository.dart';
import '../../data/repositories/policy_repository.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../domain/models/control_policy.dart';
import '../../domain/models/diaper_status.dart';
import '../../services/reminder_service.dart';

class DiaperState {
  DiaperState({
    required this.loading,
    required this.status,
    required this.policy,
    required this.countdown,
  });

  final bool loading;
  final DiaperStatus? status;
  final ControlPolicy? policy;
  final Duration? countdown;

  DiaperState copyWith({
    bool? loading,
    DiaperStatus? status,
    ControlPolicy? policy,
    Duration? countdown,
  }) {
    return DiaperState(
      loading: loading ?? this.loading,
      status: status ?? this.status,
      policy: policy ?? this.policy,
      countdown: countdown,
    );
  }

  static DiaperState initial() => DiaperState(loading: true, status: null, policy: null, countdown: null);
}

class DiaperController extends StateNotifier<DiaperState> {
  DiaperController(
    this._repo,
    this._policyRepository,
    this._reminderRepository,
    this._reminderService,
  ) : super(DiaperState.initial()) {
    _reminderService.registerDiaperChangeHandler(_handleExternalFinish);
  }

  final DiaperRepository _repo;
  final PolicyRepository _policyRepository;
  final ReminderRepository _reminderRepository;
  final ReminderService _reminderService;

  Timer? _ticker;

  Future<void> load() async {
    final policy = await _policyRepository.getByType('diaper_changing');
    var status = await _repo.fetchStatus();
    status = await _alignActiveWithPolicy(policy, status);
    state = state.copyWith(loading: false, status: status, policy: policy);
    _restartCountdown();
    if (status.nextChangeAt != null && status.active) {
      final target = DateTime.tryParse(status.nextChangeAt!);
      if (target != null && target.isAfter(DateTime.now())) {
        await _reminderRepository.setNextTrigger('diaper_changing', target);
      }
    }
  }

  Future<void> start() async {
    if (state.policy == null) return;
    final start = DateTime.now();
    final remindAfter = Duration(minutes: (state.policy!.remindHr * 60).round());
    final status = await _repo.startSession(start, remindAfter);
    state = state.copyWith(status: status);
    _restartCountdown();
    final target = DateTime.tryParse(status.nextChangeAt ?? '');
    if (target != null) {
      await _reminderRepository.setNextTrigger('diaper_changing', target);
      await _scheduleReminder(target);
    }
  }

  Future<void> stop() async {
    final status = await _repo.stopSession();
    state = state.copyWith(status: status, countdown: null);
    _ticker?.cancel();
    await _reminderService.cancelDiaperReminder();
  }

  Future<void> finishChange() async {
    final status = await _repo.finishChange(DateTime.now());
    state = state.copyWith(status: status, countdown: null);
    _ticker?.cancel();
    await _reminderService.cancelDiaperReminder();
  }

  Future<void> refreshPolicy() async {
    final policy = await _policyRepository.getByType('diaper_changing');
    var status = state.status ?? await _repo.fetchStatus();
    status = await _alignActiveWithPolicy(policy, status);
    state = state.copyWith(policy: policy, status: status);
    _restartCountdown();
  }

  void _restartCountdown() {
    _ticker?.cancel();
    final target = DateTime.tryParse(state.status?.nextChangeAt ?? '');
    if (target == null || target.isBefore(DateTime.now()) || state.status?.active != true) {
      state = state.copyWith(countdown: null);
      return;
    }
    void update() {
      final diff = target.difference(DateTime.now());
      if (diff.isNegative) {
        state = state.copyWith(countdown: Duration.zero);
        _ticker?.cancel();
        _reminderService.showDiaperNow();
        return;
      }
      state = state.copyWith(countdown: Duration(seconds: diff.inSeconds));
    }

    update();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  Future<void> _scheduleReminder(DateTime target) async {
    final now = DateTime.now();
    if (!target.isAfter(now)) return;
    await _reminderService.cancelDiaperReminder();
    await _reminderService.scheduleDiaperReminder(target);
  }

  Future<DiaperStatus> _alignActiveWithPolicy(ControlPolicy? policy, DiaperStatus status) async {
    if (policy == null) return status;
    if (!status.active) return status;
    final start = status.activeStartTime != null ? DateTime.tryParse(status.activeStartTime!) : null;
    if (start == null) return status;
    final target = start.add(Duration(minutes: (policy.remindHr * 60).round()));
    final updated = await _repo.updateNextChange(target);
    await _reminderRepository.setNextTrigger('diaper_changing', target);
    await _scheduleReminder(target);
    return updated;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _reminderService.registerDiaperChangeHandler(null);
    super.dispose();
  }

  Future<void> _handleExternalFinish() async {
    await finishChange();
  }
}
