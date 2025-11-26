import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../domain/models/daily_feast.dart';
import '../../domain/models/daily_feast_summary.dart';
import '../viewmodels/today_summary_controller.dart';
import '../viewmodels/water_controller.dart';
import 'backup_screen.dart';

const _milkBottleAsset = 'assets/icons/bottle.png';
const _peeAsset = 'assets/icons/pee.png';
const _poopAsset = 'assets/icons/poop.png';
const _feedingAsset = 'assets/icons/feeding.png';
const _yTicks = [1, 3, 5, 7, 9];

class TodaySummaryScreen extends ConsumerWidget {
  const TodaySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todaySummaryControllerProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milk Feeding ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Import / Export',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.alarm),
                    tooltip: 'View next reminder',
                    onPressed: () => _showReminderInfo(context, state),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            _BabyPane(state: state),
          if (!state.loading) ...[
            _OverviewCard(state: state),
            const SizedBox(height: 16),
            _LastSevenDaysSection(state: state),
          ],
        ],
      ),
    );
  }
}

class _BabyPane extends ConsumerWidget {
  const _BabyPane({required this.state});

  final TodaySummaryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(todaySummaryControllerProvider.notifier);
    final isActive = state.activeFeeding;
    final nextTimeText = _formatTime(state.nextFeedAt?.toIso8601String());
    final countdownText = _formatCountdown(state.nextCountdown);
    final remindersEnabled = state.remindersEnabled;
    final totalFeastSeconds = (state.summary?.totalFeastTimeSec ?? 0) + (isActive ? state.elapsed.inSeconds : 0);
    final bottleCount = state.sessions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3C2E24),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => isActive ? notifier.endFeeding() : notifier.startFeeding(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF533E31) : const Color(0xFF2F241C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? const Color(0xFFF2A45E) : const Color(0xFFD6A25E),
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))]
                            : const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white10 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(_feedingAsset, height: 110, width: 110, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              isActive ? 'Tap to stop' : 'Tap to start',
                              key: ValueKey<bool>(isActive),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              isActive ? 'Feeding in progress' : 'Ready to log a feed',
                              key: ValueKey<String>('status-$isActive'),
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            countdownText,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.start,
                   children: [
                     Text('Next time ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                     Text(
                       nextTimeText,
                       style: const TextStyle(
                         color: Color(0xFFF2A45E),
                         fontWeight: FontWeight.bold,
                       ),
                     )
                   ],
                 ),
                const SizedBox(height: 4),
                Container(
                  alignment:Alignment.topRight,
                  child: Row(
                    children: [
                      const Text(
                        'Reminder',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: remindersEnabled,
                        activeColor: const Color(0xFFF2A45E),
                        onChanged: (enabled) {
                          notifier.toggleReminders(enabled);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start At: ${_formatTime(state.activeStart?.toIso8601String() ?? state.summary?.lastFeastEndTime)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Stop At: ${_formatTime(state.summary?.lastFeastEndTime)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Total: ', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(
                        _formatShort(totalFeastSeconds),
                        style: const TextStyle(color: Color(0xFFF2A45E), fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Timer: ', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(
                        _formatClock(state.activeFeeding ? state.elapsed : Duration.zero),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showSessionsDialog(context, notifier, state.sessions),
                    child: bottleCount == 0
                        ? const Text('No sessions yet', style: TextStyle(color: Colors.white70))
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(
                              bottleCount,
                              (i) => Image.asset(_milkBottleAsset, height: 30, width: 30),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
        Text('Pee/Poop', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ToiletTile(
                label: 'Poop',
                count: state.excretory?.poopCount ?? 0,
                lastTime: state.excretory?.lastPoopTime,
                imageAsset: _poopAsset,
                onTap: notifier.incrementPoop,
                onDecrement: notifier.decrementPoop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToiletTile(
                label: 'Pee',
                count: state.excretory?.peeCount ?? 0,
                lastTime: state.excretory?.lastPeeTime,
                imageAsset: _peeAsset,
                onTap: notifier.incrementPee,
                onDecrement: notifier.decrementPee,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _nextTime(TodaySummaryState s) {
    return s.nextFeedAt?.toIso8601String();
  }
}

class _MotherPane extends ConsumerWidget {
  const _MotherPane({required this.state});

  final TodaySummaryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(waterControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mother', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Water Drinking'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _BottleControl()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today: ${waterState.water?.totalMl ?? 0} / ${(waterState.policy?.value ?? 0) * 1000 ~/ 1} ml',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _progress(waterState),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 12),
                        Text('Last drinks', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        if (waterState.log.isEmpty) const Text('No drinks yet today.'),
                        ...waterState.log.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
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
      ],
    );
  }

  double _progress(WaterState state) {
    final target = ((state.policy?.value ?? 0) * 1000).round();
    if (target == 0) return 0;
    return ((state.water?.totalMl ?? 0) / target).clamp(0.0, 1.0);
  }
}

class _OverviewCard extends ConsumerWidget {
  const _OverviewCard({required this.state});

  final TodaySummaryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(waterControllerProvider);
    final totalFeastSeconds = (state.summary?.totalFeastTimeSec ?? 0) + (state.activeFeeding ? state.elapsed.inSeconds : 0);
    return Container(
      padding:EdgeInsets.only(top: 20),
      child: _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(context, 'Today Overview'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                GestureDetector(
                  onTap: () => _showExcretoryLog(context, ref.read(todaySummaryControllerProvider.notifier), 'pee'),
                  child: _overviewStat(context, 'Total pee', (state.excretory?.peeCount ?? 0).toString(), Icons.waves),
                ),
                GestureDetector(
                  onTap: () => _showExcretoryLog(context, ref.read(todaySummaryControllerProvider.notifier), 'poop'),
                  child: _overviewStat(context, 'Total poop', (state.excretory?.poopCount ?? 0).toString(), Icons.eco_outlined),
                ),
                GestureDetector(
                  onTap: () => _showSessionsDialog(context, ref.read(todaySummaryControllerProvider.notifier), state.sessions),
                  child: _overviewStat(context, 'Milk sessions', state.sessions.length.toString(), Icons.child_care),
                ),
                GestureDetector(
                  onTap: () => _showSessionsDialog(context, ref.read(todaySummaryControllerProvider.notifier), state.sessions),
                  child: _overviewStat(context, 'Milk time', _formatShort(totalFeastSeconds), Icons.av_timer),
                ),
                _overviewStat(context, 'Water today', '${waterState.water?.totalMl ?? 0}ml', Icons.water_drop),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LastSevenDaysSection extends StatelessWidget {
  const _LastSevenDaysSection({required this.state});

  final TodaySummaryState state;

  @override
  Widget build(BuildContext context) {
    final data = state.lastSevenSummaries;
    const chartAreaHeight = 190.0;
    final dataMax = data.isEmpty
        ? 1.0
        : data
            .map((d) => [
                  d.totalFeastTimeSec / 3600, // hours
                  d.totalPee.toDouble(),
                  d.totalPooh.toDouble(),
                ].reduce((a, b) => a > b ? a : b))
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);
    final maxValue = dataMax > _yTicks.last ? dataMax : _yTicks.last.toDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2F2219),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No data yet', style: TextStyle(color: Colors.white70)),
            )
          else
            SizedBox(
              height: chartAreaHeight + 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) => _DayBar(
                  summary: data[i],
                  maxValue: maxValue,
                  barAreaHeight: chartAreaHeight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Text('x$count', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(onPressed: count > 0 ? onRemove : null, icon: const Icon(Icons.remove_circle_outline)),
              IconButton(onPressed: onAdd, icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

Widget _sectionHeader(BuildContext context, String text) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Today', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      ),
    ],
  );
}

Widget _infoChip(BuildContext context, String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ],
    ),
  );
}

Widget _overviewStat(BuildContext context, String label, String value, IconData icon) {
  return Container(
    width: 150,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).dividerColor),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ],
    ),
  );
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.summary, required this.maxValue, required this.barAreaHeight});

  final DailyFeastSummary summary;
  final double maxValue;
  final double barAreaHeight;

  @override
  Widget build(BuildContext context) {
    final feedHours = summary.totalFeastTimeSec / 3600;
    final pee = summary.totalPee.toDouble();
    final poop = summary.totalPooh.toDouble();
    final sessions = summary.totalMilkSessions;
    final feedHeight = _scaledHeight(feedHours);
    final peeHeight = _scaledHeight(pee);
    final poopHeight = _scaledHeight(poop);
    final dayLabel = _weekdayLabel(summary.date);
    final feedLabel = feedHours > 0 ? '${feedHours.toStringAsFixed(feedHours >= 10 ? 0 : 1)}h' : '';
    final poopLabel = poop > 0 ? poop.toInt().toString() : '';
    final peeLabel = pee > 0 ? pee.toInt().toString() : '';

    return SizedBox(
      width: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: barAreaHeight,
            child: Stack(
              children: [
                ..._yTicks.map((tick) {
                  final tickBottom = (tick / maxValue).clamp(0.0, 1.0) * (barAreaHeight - 14);
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: tickBottom,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '$tick',
                            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(child: Divider(color: Colors.white12, thickness: 1, height: 1)),
                      ],
                    ),
                  );
                }),
                Positioned(
                  left: 32,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bar(
                        height: feedHeight,
                        width: 20,
                        color: const Color(0xFF4D86C6),
                        text: feedLabel,
                        textColor: Colors.white,
                      ),
                      _bar(
                        height: poopHeight,
                        width: 20,
                        color: const Color(0xFFA4D86E),
                        text: poopLabel,
                        textColor: Colors.black87,
                      ),
                      _bar(
                        height: peeHeight,
                        width: 20,
                        color: const Color(0xFF6AB5E9),
                        text: peeLabel,
                        textColor: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(_milkBottleAsset, height: 18, width: 18),
              const SizedBox(width: 4),
              Image.asset(_poopAsset, height: 16, width: 16),
              const SizedBox(width: 4),
              Image.asset(_peeAsset, height: 16, width: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dayLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Text(
            sessions == 1 ? '1 time' : '$sessions times',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  double _scaledHeight(double value) {
    if (value <= 0) return 10;
    final normalized = (value / maxValue).clamp(0.06, 1.0);
    // Leave a little headroom to avoid text overflow inside the bar.
    return normalized * (barAreaHeight - 14);
  }

  Widget _bar({
    required double height,
    required double width,
    required Color color,
    required String text,
    required Color textColor,
  }) {
    final showLabel = text.isNotEmpty && height > 22;
    return Container(
      height: height,
      width: width,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: showLabel ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4) : EdgeInsets.zero,
      child: !showLabel
          ? const SizedBox.shrink()
          : Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: textColor),
            ),
    );
  }
}

String _weekdayLabel(String isoDate) {
  DateTime? dt;
  try {
    dt = DateTime.parse(isoDate);
  } catch (_) {
    return isoDate;
  }
  const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  return days[(dt.weekday % 7)];
}

String _formatTime(String? iso) {
  if (iso == null) return '--';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '--';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatClock(Duration duration) {
  final h = duration.inHours.toString().padLeft(2, '0');
  final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatCountdown(Duration? duration) {
  if (duration == null) return '--:--:--';
  final h = duration.inHours.toString().padLeft(2, '0');
  final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatShort(int seconds) {
  final duration = Duration(seconds: seconds);
  final h = duration.inHours;
  final m = duration.inMinutes % 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}

void _showSessionsDialog(BuildContext context, TodaySummaryController notifier, List<DailyFeast> sessions) {
  showDialog(
    context: context,
    builder: (ctx) {
      if (sessions.isEmpty) {
        return AlertDialog(
          title: const Text('Milk sessions'),
          content: const Text('No sessions logged yet.'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
        );
      }
      return AlertDialog(
        title: const Text('Milk sessions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Builder(builder: (_) {
            final latestStart = sessions
                .map((s) => DateTime.tryParse(s.startTime))
                .whereType<DateTime>()
                .fold<DateTime?>(null, (max, cur) => max == null || cur.isAfter(max) ? cur : max);
            return ListView.separated(
              shrinkWrap: true,
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = sessions[i];
                final start = DateTime.tryParse(s.startTime);
                final end = DateTime.tryParse(s.endTime);
                final duration = Duration(seconds: s.durationSec);
                final timeLabel =
                    start != null && end != null ? '${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}' : '--';
                final isLatest = latestStart != null && (start?.isAtSameMomentAs(latestStart) ?? false);
                return ListTile(
                  leading: Image.asset(_milkBottleAsset, height: 24, width: 24),
                  title: Text('${_formatShort(duration.inSeconds)}'),
                  subtitle: Text(timeLabel),
                  trailing: isLatest
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await notifier.removeMilkSession(s);
                            Navigator.of(ctx).pop();
                          },
                        ),
                );
              },
            );
          }),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
      );
    },
  );
}

void _showReminderInfo(BuildContext context, TodaySummaryState state) {
  final next = state.nextFeedAt;
  final reminderAt = state.summary?.reminderAt != null ? DateTime.tryParse(state.summary!.reminderAt!) : null;
  final lastFeed = state.summary?.lastFeedingTime != null ? DateTime.tryParse(state.summary!.lastFeedingTime!) : null;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Next milk reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reminder at: ${_formatTimeFull(reminderAt) ?? '--'}'),
          const SizedBox(height: 6),
          Text('Next countdown target: ${_formatTimeFull(next) ?? '--'}'),
          const SizedBox(height: 6),
          Text('Last feeding: ${_formatTimeFull(lastFeed) ?? '--'}'),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
    ),
  );
}

Future<void> _showExcretoryLog(BuildContext context, TodaySummaryController notifier, String type) async {
  var entries = await notifier.fetchExcretoryLog(type);
  final label = type == 'pee' ? 'Pee' : 'Poop';
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final total = entries.length;
        Widget content;
        if (entries.isEmpty) {
          content = const Text('No records yet today.');
        } else {
          content = SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Total today: $total', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final time = entries[i];
                      return ListTile(
                        leading: Icon(type == 'pee' ? Icons.water_drop : Icons.catching_pokemon_outlined),
                        title: Text(_formatTimeFull(time) ?? '--'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete ,color: Colors.red,),
                          onPressed: () async {
                            await notifier.removeExcretoryEntry(time, type);
                            final updated = await notifier.fetchExcretoryLog(type);
                            setState(() => entries = updated);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return AlertDialog(
          title: Text('$label today'),
          content: content,
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        );
      },
    ),
  );
}

String? _formatTimeFull(DateTime? dt) {
  if (dt == null) return null;
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class _BottleControl extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(waterControllerProvider.notifier);
    final zones = [
      {'label': '+300 ml', 'amount': 300, 'color': Theme.of(context).colorScheme.secondary.withOpacity(0.3)},
      {'label': '+300 ml', 'amount': 300, 'color': Theme.of(context).colorScheme.primary.withOpacity(0.6)},
      {'label': '+400 ml', 'amount': 400, 'color': Theme.of(context).colorScheme.secondary.withOpacity(0.5)},
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
                          onTap: () => notifier.addWater(z['amount'] as int),
                          child: Container(
                            color: (z['color'] as Color).withOpacity(0.9),
                            alignment: Alignment.center,
                            child: Text(
                              z['label'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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

class _ToiletTile extends StatelessWidget {
  const _ToiletTile({
    required this.label,
    required this.count,
    required this.lastTime,
    required this.imageAsset,
    required this.onTap,
    required this.onDecrement,
  });

  final String label;
  final int count;
  final String? lastTime;
  final String imageAsset;
  final VoidCallback onTap;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset(imageAsset, height: 120, fit: BoxFit.contain)),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: count > 0 ? onDecrement : null,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.remove, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$label - ', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(count.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Last time at ${_formatTime(lastTime)}'),
          ],
        ),
      ),
    );
  }
}
