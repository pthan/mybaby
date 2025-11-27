import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/setting_repository.dart';
import '../../domain/models/setting.dart';

class SettingState {
  SettingState({
    required this.loading,
    required this.items,
  });

  final bool loading;
  final List<Setting> items;

  SettingState copyWith({bool? loading, List<Setting>? items}) {
    return SettingState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
    );
  }

  bool isEnabled(String name) {
    return items.firstWhere(
          (s) => s.settingname == name,
          orElse: () => Setting(id: null, settingname: name, displayName: name, enable: false),
        ).enable;
  }

  ThemeMode themeMode() => isEnabled('dark_mode') ? ThemeMode.dark : ThemeMode.light;

  bool get darkMode => isEnabled('dark_mode');
}

class SettingController extends StateNotifier<SettingState> {
  SettingController(this._repo)
      : super(
          SettingState(
            loading: true,
            items: const [],
          ),
        );

  final SettingRepository _repo;

  Future<void> load() async {
    final items = await _repo.fetchAll();
    state = state.copyWith(loading: false, items: items);
  }

  Future<void> toggle(String name, bool enable) async {
    final nextItems = state.items
        .map((s) => s.settingname == name ? s.copyWith(enable: enable) : s)
        .toList(growable: false);
    // Optimistically update UI/theme immediately.
    state = state.copyWith(items: nextItems);
    await _repo.updateEnable(name, enable);
  }

  ThemeMode themeMode() => state.themeMode();

  bool isDarkMode() => state.darkMode;
}
