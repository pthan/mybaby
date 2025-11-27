import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingControllerProvider);
    final notifier = ref.read(settingControllerProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final setting = state.items[index];
                final surface = theme.cardColor;
                final onSurface = theme.colorScheme.onSurface;
                return Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(setting.displayName, style: TextStyle(color: onSurface, fontWeight: FontWeight.w600)),
                    subtitle: Text(setting.settingname, style: TextStyle(color: onSurface.withOpacity(0.7))),
                    trailing: Switch(
                      value: setting.enable,
                      activeColor: theme.colorScheme.onPrimary,
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveThumbColor: onSurface.withOpacity(0.7),
                      inactiveTrackColor: onSurface.withOpacity(0.3),
                      onChanged: (val) => notifier.toggle(setting.settingname, val),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: state.items.length,
            ),
    );
  }
}
