import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/excretory_repository.dart';
import '../../data/repositories/feast_repository.dart';
import '../../data/repositories/policy_repository.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../domain/models/control_policy.dart';
import '../../domain/models/daily_excretory.dart';
import '../../domain/models/daily_feast.dart';
import '../../domain/models/daily_feast_summary.dart';
import '../../domain/utils/date_key.dart';
import '../../services/reminder_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TodaySummaryState {
  TodaySummaryState({
    required this.loading,
    required this.excretory,
    required this.summary,
    required this.sessions,
    required this.milkPolicy,
    required this.activeFeeding,
    required this.activeStart,
    required this.elapsed,
    required this.nextFeedAt,
    required this.nextCountdown,
    required this.remindersEnabled,
    required this.lastSevenSummaries,
  });

  static const _unset = Object();

  final bool loading;
  final DailyExcretory? excretory;
  final DailyFeastSummary? summary;
  final List<DailyFeast> sessions;
  final ControlPolicy? milkPolicy;
  final bool activeFeeding;
  final DateTime? activeStart;
  final Duration elapsed;
  final DateTime? nextFeedAt;
  final Duration? nextCountdown;
  final bool remindersEnabled;
  final List<DailyFeastSummary> lastSevenSummaries;

  TodaySummaryState copyWith({
    Object? loading = _unset,
    Object? excretory = _unset,
    Object? summary = _unset,
    Object? sessions = _unset,
    Object? milkPolicy = _unset,
    Object? activeFeeding = _unset,
    Object? activeStart = _unset,
    Object? elapsed = _unset,
    Object? nextFeedAt = _unset,
    Object? nextCountdown = _unset,
    Object? remindersEnabled = _unset,
    Object? lastSevenSummaries = _unset,
  }) {
    return TodaySummaryState(
      loading: identical(loading, _unset) ? this.loading : loading as bool,
      excretory: identical(excretory, _unset) ? this.excretory : excretory as DailyExcretory?,
      summary: identical(summary, _unset) ? this.summary : summary as DailyFeastSummary?,
      sessions: identical(sessions, _unset) ? this.sessions : sessions as List<DailyFeast>,
      milkPolicy: identical(milkPolicy, _unset) ? this.milkPolicy : milkPolicy as ControlPolicy?,
      activeFeeding: identical(activeFeeding, _unset) ? this.activeFeeding : activeFeeding as bool,
      activeStart: identical(activeStart, _unset) ? this.activeStart : activeStart as DateTime?,
      elapsed: identical(elapsed, _unset) ? this.elapsed : elapsed as Duration,
      nextFeedAt: identical(nextFeedAt, _unset) ? this.nextFeedAt : nextFeedAt as DateTime?,
      nextCountdown: identical(nextCountdown, _unset) ? this.nextCountdown : nextCountdown as Duration?,
      remindersEnabled: identical(remindersEnabled, _unset) ? this.remindersEnabled : remindersEnabled as bool,
      lastSevenSummaries:
          identical(lastSevenSummaries, _unset) ? this.lastSevenSummaries : lastSevenSummaries as List<DailyFeastSummary>,
    );
  }

  static TodaySummaryState initial() => TodaySummaryState(
        loading: true,
        excretory: null,
        summary: null,
        sessions: const [],
        milkPolicy: null,
        activeFeeding: false,
        activeStart: null,
        elapsed: Duration.zero,
        nextFeedAt: null,
        nextCountdown: null,
        remindersEnabled: true,
        lastSevenSummaries: const [],
      );
}

class TodaySummaryController extends StateNotifier<TodaySummaryState> {
  TodaySummaryController(
    this._excretoryRepository,
    this._feastRepository,
    this._policyRepository,
    this._reminderRepository,
    this._reminderService,
  ) : super(TodaySummaryState.initial());

  final ExcretoryRepository _excretoryRepository;
  final FeastRepository _feastRepository;
  final PolicyRepository _policyRepository;
  final ReminderRepository _reminderRepository;
  final ReminderService _reminderService;

  Timer? _ticker;
  Timer? _countdownTicker;

  Future<void> load() async {
    final excretory = await _excretoryRepository.fetchToday();
    var summary = await _feastRepository.fetchSummaryToday();
    final sessions = await _feastRepository.sessionsToday();
    final policy = await _policyRepository.getByType('feast_milk');
    var remindersEnabled = summary.alarmEnable;
    var next = _computeNextFeed(summary, policy);
    final staleReminder = summary.reminderAt != null && (DateTime.tryParse(summary.reminderAt!)?.isBefore(DateTime.now()) ?? false);
    if ((summary.reminderAt == null || staleReminder) && next != null) {
      summary = await _feastRepository.saveReminderFields(
        reminderAt: next,
        lastFeedingTime: _lastFeedingTime(summary),
        alarmEnabled: remindersEnabled,
      );
      remindersEnabled = summary.alarmEnable;
      next = _computeNextFeed(summary, policy);
    }
    // Guard: if next is still stale, drop it (do not fire expired alarms).
    if (next != null && next.isBefore(DateTime.now())) {
      next = null;
      try {
        unawaited(_reminderService.cancelMilkReminder());
      } catch (_) {}
    }
    state = state.copyWith(
      loading: false,
      excretory: excretory,
      summary: summary,
      sessions: sessions,
      milkPolicy: policy,
      remindersEnabled: remindersEnabled,
      nextFeedAt: next,
      nextCountdown: remindersEnabled ? _computeCountdown(next) : null,
    );
    await _refreshRecentSummaries();
    _restartCountdownTimer();
    if (next != null && remindersEnabled) {
      await _scheduleMilkReminder(next);
    }
  }

  Future<void> incrementPee() async {
    final updated = await _excretoryRepository.incrementPee();
    final summary = await _feastRepository.fetchSummaryToday();
    state = state.copyWith(excretory: updated, summary: summary);
    await _refreshRecentSummaries();
  }

  Future<void> decrementPee() async {
    final updated = await _excretoryRepository.decrementPee();
    final summary = await _feastRepository.fetchSummaryToday();
    state = state.copyWith(excretory: updated, summary: summary);
    await _refreshRecentSummaries();
  }

  Future<void> incrementPoop() async {
    final updated = await _excretoryRepository.incrementPoop();
    final summary = await _feastRepository.fetchSummaryToday();
    state = state.copyWith(excretory: updated, summary: summary);
    await _refreshRecentSummaries();
  }

  Future<void> decrementPoop() async {
    final updated = await _excretoryRepository.decrementPoop();
    final summary = await _feastRepository.fetchSummaryToday();
    state = state.copyWith(excretory: updated, summary: summary);
    await _refreshRecentSummaries();
  }

  Future<List<DateTime>> fetchExcretoryLog(String type) {
    return _excretoryRepository.fetchLogsToday(type);
  }

  Future<void> removeExcretoryEntry(DateTime time, String type) async {
    final updated = await _excretoryRepository.removeLog(time, type);
    final summary = await _feastRepository.fetchSummaryToday();
    state = state.copyWith(excretory: updated, summary: summary);
    await _refreshRecentSummaries();
  }

  Future<void> removeMilkSession(DailyFeast session) async {
    if (session.id == null) return;
    final summary = await _feastRepository.removeSession(session.id!, session.durationSec);
    final sessions = await _feastRepository.sessionsToday();
    state = state.copyWith(summary: summary, sessions: sessions);
    await _refreshRecentSummaries();
    _restartCountdownTimer();
  }

  Future<void> startFeeding() async {
    if (state.activeFeeding) return;
    _ticker?.cancel();
    _countdownTicker?.cancel();
    final start = DateTime.now();
    state = state.copyWith(
      activeFeeding: true,
      activeStart: start,
      elapsed: Duration.zero,
      nextFeedAt: null,
      nextCountdown: null,
    );
    // Even if reminders or wakelock fail, keep the UI responsive.
    try {
      await _reminderService.cancelMilkReminder();
    } catch (_) {}
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: DateTime.now().difference(start));
    });
  }

  Future<void> endFeeding() async {
    if (!state.activeFeeding || state.activeStart == null) return;
    final start = state.activeStart!;
    final end = DateTime.now();
    final duration = end.difference(start);
    final baseNextReminder = _nextFromPolicy(end, state.milkPolicy);
    var remindersEnabled = state.remindersEnabled;
    _ticker?.cancel();
    try {
      await WakelockPlus.disable();
    } catch (_) {}

    // Optimistically update UI so button/colour/totals refresh immediately.
    final optimisticNext = _nextFromPolicy(end, state.milkPolicy);
    final optimisticSummary = _buildOptimisticSummary(end, duration, optimisticNext);
    final optimisticSessions = [
      DailyFeast(
        id: null,
        date: todayKey(),
        type: 'baby_milk_feast',
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
        durationSec: duration.inSeconds,
      ),
      ...state.sessions,
    ];
    state = state.copyWith(
      activeFeeding: false,
      activeStart: null,
      elapsed: Duration.zero,
      summary: optimisticSummary,
      sessions: optimisticSessions,
      nextFeedAt: optimisticNext,
      nextCountdown: remindersEnabled ? _computeCountdown(optimisticNext) : null,
    );

    final summary = await _feastRepository.addSession(
      start,
      end,
      nextReminder: optimisticNext,
      alarmEnabled: state.remindersEnabled,
    );
    final sessions = await _feastRepository.sessionsToday();
    remindersEnabled = summary.alarmEnable;
    final nextFromPolicy = baseNextReminder ?? _nextFromPolicy(end, state.milkPolicy);
    final next = remindersEnabled ? (nextFromPolicy ?? _computeNextFeed(summary, state.milkPolicy)) : null;
    var updatedSummary = await _feastRepository.saveReminderFields(
      reminderAt: next,
      lastFeedingTime: end,
      alarmEnabled: remindersEnabled,
    );
    if (next != null && remindersEnabled) {
      await _reminderRepository.setNextTrigger('feast_milk', next);
      try {
        await _reminderService.scheduleMilkReminder(next);
      } catch (_) {}
    } else {
      try {
        await _reminderService.cancelMilkReminder();
      } catch (_) {}
    }
    // Guarantee a usable next reminder after stopping, even if persistence returned null/stale.
    DateTime? ensuredNext = next;
    if (ensuredNext == null && state.milkPolicy != null) {
      final lastFeed = _lastFeedingTime(updatedSummary) ?? end;
      ensuredNext = lastFeed.add(Duration(minutes: (state.milkPolicy!.remindHr * 60).round()));
      updatedSummary = await _feastRepository.saveReminderFields(
        reminderAt: ensuredNext,
        lastFeedingTime: lastFeed,
        alarmEnabled: remindersEnabled,
      );
      ensuredNext = _computeNextFeed(updatedSummary, state.milkPolicy);
      if (ensuredNext != null && remindersEnabled) {
        await _reminderRepository.setNextTrigger('feast_milk', ensuredNext);
        try {
          await _reminderService.scheduleMilkReminder(ensuredNext);
        } catch (_) {}
      }
    }
    state = state.copyWith(
      summary: updatedSummary,
      sessions: sessions,
      remindersEnabled: remindersEnabled,
      nextFeedAt: ensuredNext,
      nextCountdown: remindersEnabled ? _computeCountdown(ensuredNext) : null,
    );
    await _refreshRecentSummaries();
    _restartCountdownTimer();
  }

  DateTime? _lastFeedingTime(DailyFeastSummary? summary) {
    if (summary == null) return null;
    final raw = summary.lastFeedingTime ?? summary.lastFeastEndTime;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  DateTime? _computeNextFeed(DailyFeastSummary? summary, ControlPolicy? policy) {
    if (summary == null) return null;
    final reminder = summary.reminderAt != null ? DateTime.tryParse(summary.reminderAt!) : null;
    final last = _lastFeedingTime(summary);
    DateTime? nextFromPolicy;
    if (last != null && policy != null) {
      final minutes = (policy.remindHr * 60).round();
      nextFromPolicy = last.add(Duration(minutes: minutes));
    }
    if (reminder != null && reminder.isAfter(DateTime.now())) {
      return reminder;
    }
    return nextFromPolicy ?? reminder;
  }

  Duration? _computeCountdown(DateTime? next) {
    if (next == null) return null;
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return null;
    return Duration(seconds: diff.inSeconds); // floor to whole seconds to keep the UI ticking predictably
  }

  void _restartCountdownTimer() {
    _countdownTicker?.cancel();
    if (!state.remindersEnabled) {
      state = state.copyWith(nextCountdown: null);
      return;
    }

    // Keep a single fixed target per run; recompute only when restarting.
    DateTime? target = state.nextFeedAt ?? _computeNextFeed(state.summary, state.milkPolicy);
    final now = DateTime.now();
    if (target != null && target.isBefore(now)) {
      target = _computeNextFeed(state.summary, state.milkPolicy);
      if (target != null && target.isBefore(now)) {
        target = null;
      }
    }
    if (target == null) {
      state = state.copyWith(nextFeedAt: null, nextCountdown: null);
      try {
        unawaited(_reminderService.cancelMilkReminder());
      } catch (_) {}
      return;
    }

    void updateCountdown() {
      final diff = target!.difference(DateTime.now());
      final remaining = diff.isNegative ? null : Duration(seconds: diff.inSeconds);
      state = state.copyWith(nextFeedAt: target, nextCountdown: remaining);
    }

    updateCountdown();
    if (state.nextCountdown == null) {
      return;
    }

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      updateCountdown();
      final remaining = state.nextCountdown ?? Duration.zero;
      if (remaining <= Duration.zero) {
        _countdownTicker?.cancel();
        if (state.remindersEnabled) {
          try {
            unawaited(_reminderService.showMilkNow());
          } catch (_) {}
        }
      }
    });
  }

  Future<void> refreshPolicy() async {
    final policy = await _policyRepository.getByType('feast_milk');
    // Fetch latest summary to avoid stale reminder_at after DB updates.
    var summary = await _feastRepository.fetchSummaryToday();
    final last = _lastFeedingTime(summary);
    final nextFromPolicy = (last != null && policy != null)
        ? last.add(Duration(minutes: (policy.remindHr * 60).round()))
        : null;
    summary = await _feastRepository.saveReminderFields(
      reminderAt: nextFromPolicy,
      lastFeedingTime: last,
      alarmEnabled: summary.alarmEnable,
    );
    final nextFromSummary = _computeNextFeed(summary, policy);
    final remindersEnabled = summary.alarmEnable;
    state = state.copyWith(
      summary: summary,
      milkPolicy: policy,
      remindersEnabled: remindersEnabled,
      nextFeedAt: nextFromSummary,
      nextCountdown: remindersEnabled ? _computeCountdown(nextFromSummary) : null,
    );
    _restartCountdownTimer();
    await _refreshRecentSummaries();
    if (nextFromSummary != null && remindersEnabled) {
      // Cancel any pending alarm and reschedule using the new policy window.
      try {
        await _reminderService.cancelMilkReminder();
      } catch (_) {}
      await _reminderRepository.setNextTrigger('feast_milk', nextFromSummary);
      await _scheduleMilkReminder(nextFromSummary);
    } else {
      try {
        await _reminderService.cancelMilkReminder();
      } catch (_) {}
    }
  }

  DailyFeastSummary _buildOptimisticSummary(DateTime end, Duration duration, DateTime? nextReminder) {
    final existing = state.summary;
    final nowIso = DateTime.now().toIso8601String();
    final reminderIso = nextReminder?.toIso8601String();
    final alarmEnabled = state.remindersEnabled;
    if (existing == null) {
      return DailyFeastSummary(
        id: null,
        date: todayKey(),
        totalFeastTimeSec: duration.inSeconds,
        totalMilkSessions: 1,
        totalPee: 0,
        totalPooh: 0,
        alarmEnable: alarmEnabled,
        reminderAt: reminderIso,
        lastFeedingTime: end.toIso8601String(),
        lastFeastEndTime: end.toIso8601String(),
        createdAt: nowIso,
        updatedAt: nowIso,
      );
    }
    return existing.copyWith(
      totalFeastTimeSec: existing.totalFeastTimeSec + duration.inSeconds,
      totalMilkSessions: existing.totalMilkSessions + 1,
      alarmEnable: alarmEnabled,
      reminderAt: reminderIso ?? existing.reminderAt,
      lastFeedingTime: end.toIso8601String(),
      lastFeastEndTime: end.toIso8601String(),
      updatedAt: nowIso,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _countdownTicker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> toggleReminders(bool enabled) async {
    var summary = state.summary;
    if (summary != null) {
      final nextReminder = state.nextFeedAt ?? _computeNextFeed(summary, state.milkPolicy);
      summary = await _feastRepository.saveReminderFields(
        reminderAt: nextReminder,
        lastFeedingTime: _lastFeedingTime(summary),
        alarmEnabled: enabled,
      );
    }
    final next = summary != null ? _computeNextFeed(summary, state.milkPolicy) : state.nextFeedAt;
    state = state.copyWith(
      summary: summary ?? state.summary,
      remindersEnabled: enabled,
      nextFeedAt: next,
      nextCountdown: enabled ? _computeCountdown(next) : null,
    );
    if (!enabled) {
      _countdownTicker?.cancel();
      state = state.copyWith(nextCountdown: null);
      try {
        await _reminderService.cancelMilkReminder();
      } catch (_) {}
      return;
    }

    _restartCountdownTimer();
    final target = state.nextFeedAt;
    if (target != null) {
      await _scheduleMilkReminder(target);
    }
  }

  Future<void> _refreshRecentSummaries() async {
    final recent = await _feastRepository.fetchRecentSummaries(days: 7);
    // Show oldest to newest left-to-right for the chart.
    state = state.copyWith(lastSevenSummaries: recent.reversed.toList());
  }

  Future<void> _scheduleMilkReminder(DateTime next) async {
    final now = DateTime.now();
    if (!next.isAfter(now)) return;
    final target = next;
    try {
      await _reminderService.cancelMilkReminder();
    } catch (_) {}
    await _reminderRepository.setNextTrigger('feast_milk', target);
    try {
      await _reminderService.scheduleMilkReminder(target);
    } catch (_) {}
  }

  DateTime? _nextFromPolicy(DateTime end, ControlPolicy? policy) {
    if (policy == null) return null;
    final minutes = (policy.remindHr * 60).round();
    return end.add(Duration(minutes: minutes));
  }
}
