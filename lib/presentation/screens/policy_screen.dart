import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(policyControllerProvider);
    final notifier = ref.read(policyControllerProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Policy & Reminders', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (state.loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Milk feeding (control_policy.feast_milk)'),
                    const SizedBox(height: 12),
                    Text('Target every ${state.milkPolicy!.value.toStringAsFixed(1)} hours'),
                    Slider(
                      value: state.milkPolicy!.value,
                      min: 1.0,
                      max: 4.0,
                      divisions: 6,
                      label: '${state.milkPolicy!.value.toStringAsFixed(1)}h',
                      onChanged: notifier.updateMilk,
                    ),
                    Text('Reminder every ${_formatReminderLabel(state.milkPolicy!.remindHr)}'),
                    _ReminderPicker(
                      value: state.milkPolicy!.remindHr,
                      onChanged: notifier.updateMilkReminder,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Water drinking (control_policy.water_drink)'),
                    const SizedBox(height: 12),
                    Text('Daily target ${state.waterPolicy!.value.toStringAsFixed(1)} L (${(state.waterPolicy!.value * 1000).round()} ml)'),
                    Slider(
                      value: state.waterPolicy!.value,
                      min: 2.0,
                      max: 4.0,
                      divisions: 8,
                      label: '${state.waterPolicy!.value.toStringAsFixed(1)}L',
                      onChanged: notifier.updateWaterTarget,
                    ),
                    const SizedBox(height: 4),
                    Text('Reminder every ${_formatReminderLabel(state.waterPolicy!.remindHr)}'),
                    _ReminderPicker(
                      value: state.waterPolicy!.remindHr,
                      onChanged: notifier.updateWaterReminder,
                    ),
                    const SizedBox(height: 4),
                    const Text('Values persist in the control_policy table; tie ReminderService to reminder_schedule for notifications.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Diaper changing (control_policy.diaper_changing)'),
                    const SizedBox(height: 12),
                    Text('Reminder every ${_formatReminderLabel(state.diaperPolicy!.remindHr)}'),
                    _DiaperReminderSlider(
                      value: state.diaperPolicy!.remindHr,
                      onChanged: notifier.updateDiaperReminder,
                    ),
                    const SizedBox(height: 4),
                    const Text('Slider steps: 5-30 min, then 1-5 hours.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _sectionHeader(String text) {
  return Row(
    children: [
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0BA8A4).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Policy', style: TextStyle(color: Color(0xFF0BA8A4), fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

String _formatReminderLabel(double hours) {
  if (hours < 1) {
    final minutes = (hours * 60).round();
    return '$minutes min';
  }
  final wholeHour = hours % 1 == 0;
  return '${hours.toStringAsFixed(wholeHour ? 0 : 1)} h';
}

class _ReminderPicker extends StatelessWidget {
  const _ReminderPicker({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const _options = <double>[
    2 / 60, // 2 min
    10 / 60, // 10 min
    30 / 60, // 30 min
    45 / 60, // 45 min
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
  ];

  @override
  Widget build(BuildContext context) {
    final current = _nearest(value);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options
          .map(
            (v) => ChoiceChip(
              label: Text(_formatReminderLabel(v)),
              selected: v == current,
              onSelected: (_) => onChanged(v),
            ),
          )
          .toList(),
    );
  }

  double _nearest(double raw) {
    return _options.reduce((a, b) => (raw - a).abs() <= (raw - b).abs() ? a : b);
  }
}

class _DiaperReminderSlider extends StatelessWidget {
  const _DiaperReminderSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const _stops = <double>[
    5 / 60,
    10 / 60,
    20 / 60,
    30 / 60,
    1,
    2,
    3,
    4,
    5,
  ];

  @override
  Widget build(BuildContext context) {
    final nearest = _nearest(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: nearest,
          min: _stops.first,
          max: _stops.last,
          divisions: _stops.length - 1,
          label: _formatReminderLabel(nearest),
          onChanged: (v) => onChanged(_nearest(v)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _stops
              .map(
                (v) => ChoiceChip(
                  label: Text(_formatReminderLabel(v)),
                  selected: v == nearest,
                  onSelected: (_) => onChanged(v),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  double _nearest(double raw) {
    return _stops.reduce((a, b) => (raw - a).abs() <= (raw - b).abs() ? a : b);
  }
}
