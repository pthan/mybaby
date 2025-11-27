import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/policy_repository.dart';
import '../../domain/models/control_policy.dart';

class PolicyState {
  PolicyState({
    required this.loading,
    required this.milkPolicy,
    required this.waterPolicy,
    required this.diaperPolicy,
  });

  final bool loading;
  final ControlPolicy? milkPolicy;
  final ControlPolicy? waterPolicy;
  final ControlPolicy? diaperPolicy;

  PolicyState copyWith({
    bool? loading,
    ControlPolicy? milkPolicy,
    ControlPolicy? waterPolicy,
    ControlPolicy? diaperPolicy,
  }) {
    return PolicyState(
      loading: loading ?? this.loading,
      milkPolicy: milkPolicy ?? this.milkPolicy,
      waterPolicy: waterPolicy ?? this.waterPolicy,
      diaperPolicy: diaperPolicy ?? this.diaperPolicy,
    );
  }

  static PolicyState initial() => PolicyState(loading: true, milkPolicy: null, waterPolicy: null, diaperPolicy: null);
}

class PolicyController extends StateNotifier<PolicyState> {
  PolicyController(
    this._repo, {
    required this.onMilkPolicyChanged,
    required this.onWaterPolicyChanged,
    required this.onDiaperPolicyChanged,
  }) : super(PolicyState.initial());

  final PolicyRepository _repo;
  final Future<void> Function() onMilkPolicyChanged;
  final Future<void> Function() onWaterPolicyChanged;
  final Future<void> Function() onDiaperPolicyChanged;

  Future<void> load() async {
    final milk = await _repo.getByType('feast_milk');
    final water = await _repo.getByType('water_drink');
    final diaper = await _repo.getByType('diaper_changing');
    state = state.copyWith(loading: false, milkPolicy: milk, waterPolicy: water, diaperPolicy: diaper);
  }

  Future<void> updateMilk(double hours) async {
    final current = state.milkPolicy;
    if (current == null) return;
    await _repo.updateValue('feast_milk', hours, current.remindHr);
    state = state.copyWith(milkPolicy: current.copyWith(value: hours));
    await onMilkPolicyChanged();
  }

  Future<void> updateMilkReminder(double hours) async {
    final current = state.milkPolicy;
    if (current == null) return;
    await _repo.updateValue('feast_milk', current.value, hours);
    state = state.copyWith(milkPolicy: current.copyWith(remindHr: hours));
    await onMilkPolicyChanged();
  }

  Future<void> updateWaterTarget(double liters) async {
    final current = state.waterPolicy;
    if (current == null) return;
    await _repo.updateValue('water_drink', liters, current.remindHr);
    state = state.copyWith(waterPolicy: current.copyWith(value: liters));
    await onWaterPolicyChanged();
  }

  Future<void> updateWaterReminder(double hours) async {
    final current = state.waterPolicy;
    if (current == null) return;
    await _repo.updateValue('water_drink', current.value, hours);
    state = state.copyWith(waterPolicy: current.copyWith(remindHr: hours));
    await onWaterPolicyChanged();
  }

  Future<void> updateDiaperReminder(double hours) async {
    final current = state.diaperPolicy;
    if (current == null) return;
    await _repo.updateValue('diaper_changing', current.value, hours);
    state = state.copyWith(diaperPolicy: current.copyWith(remindHr: hours));
    await onDiaperPolicyChanged();
  }
}
