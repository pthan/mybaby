import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/policy_repository.dart';
import '../../domain/models/control_policy.dart';

class PolicyState {
  PolicyState({
    required this.loading,
    required this.milkPolicy,
    required this.waterPolicy,
  });

  final bool loading;
  final ControlPolicy? milkPolicy;
  final ControlPolicy? waterPolicy;

  PolicyState copyWith({
    bool? loading,
    ControlPolicy? milkPolicy,
    ControlPolicy? waterPolicy,
  }) {
    return PolicyState(
      loading: loading ?? this.loading,
      milkPolicy: milkPolicy ?? this.milkPolicy,
      waterPolicy: waterPolicy ?? this.waterPolicy,
    );
  }

  static PolicyState initial() => PolicyState(loading: true, milkPolicy: null, waterPolicy: null);
}

class PolicyController extends StateNotifier<PolicyState> {
  PolicyController(
    this._repo, {
    required this.onMilkPolicyChanged,
    required this.onWaterPolicyChanged,
  }) : super(PolicyState.initial());

  final PolicyRepository _repo;
  final Future<void> Function() onMilkPolicyChanged;
  final Future<void> Function() onWaterPolicyChanged;

  Future<void> load() async {
    final milk = await _repo.getByType('feast_milk');
    final water = await _repo.getByType('water_drink');
    state = state.copyWith(loading: false, milkPolicy: milk, waterPolicy: water);
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
}
