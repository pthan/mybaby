import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../viewmodels/water_controller.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waterControllerProvider);
    final notifier = ref.read(waterControllerProvider.notifier);
    final targetMl = ((state.policy?.value ?? 0) * 1000).round();
    final progress = targetMl == 0 ? 0.0 : ((state.water?.totalMl ?? 0) / targetMl).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Water Drinking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BottleControl(onAdd: notifier.addWater),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today: ${state.water?.totalMl ?? 0} / $targetMl ml',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(8)),
                            const SizedBox(height: 14),
                            Text('Recent drinks', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            if (state.log.isEmpty) const Text('No drinks yet. Tap the bottle to log.'),
                            ...state.log.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_drink, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text('+${e['amount_ml']} ml at ${_formatTime(e['time'] as String?)}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleControl extends StatelessWidget {
  const _BottleControl({required this.onAdd});

  final void Function(int) onAdd;

  @override
  Widget build(BuildContext context) {
    final zones = [
      {'label': '+300 ml', 'amount': 300, 'color': Theme.of(context).colorScheme.secondary.withOpacity(0.35)},
      {'label': '+300 ml', 'amount': 300, 'color': Theme.of(context).colorScheme.primary.withOpacity(0.65)},
      {'label': '+400 ml', 'amount': 400, 'color': Theme.of(context).colorScheme.secondary.withOpacity(0.55)},
    ];
    return Container(
      height: 320,
      width: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Icon(Icons.local_drink, color: Theme.of(context).colorScheme.primary),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              child: Column(
                children: zones
                    .map(
                      (z) => Expanded(
                        child: GestureDetector(
                          onTap: () => onAdd(z['amount'] as int),
                          child: Container(
                            color: (z['color'] as Color).withOpacity(0.9),
                            alignment: Alignment.center,
                            child: Text(
                              z['label'] as String,
                              style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(String? iso) {
  if (iso == null) return '--';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '--';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
