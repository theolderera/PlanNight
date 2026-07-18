import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../data/api/api_error.dart';
import '../../data/models/stats.dart';
import 'stats_providers.dart';

/// Weekly Summary — the app's centrepiece. A completion-per-day bar chart, hero
/// stat tiles (streak, weekly rate, successful days), and a monthly trend line.
/// Single-series charts, so one hue (theme primary); success is an emphasis of
/// that hue, exact values on touch, recessive axes, ink-coloured text.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime _weekStart = Dates.startOfWeek(Dates.today());

  bool get _isCurrentWeek =>
      Dates.isSameDay(_weekStart, Dates.startOfWeek(Dates.today()));

  DateRange get _weekRange => (
        from: Dates.iso(_weekStart),
        to: Dates.iso(Dates.addDays(_weekStart, 6)),
      );

  DateRange get _monthRange => (
        from: Dates.iso(Dates.addDays(Dates.today(), -29)),
        to: Dates.iso(Dates.today()),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weekAsync = ref.watch(summaryProvider(_weekRange));
    final monthAsync = ref.watch(summaryProvider(_monthRange));
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(summaryProvider);
          ref.invalidate(streakProvider);
          await ref.read(summaryProvider(_weekRange).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _HeroRow(streakAsync: streakAsync, weekAsync: weekAsync),
            const SizedBox(height: 20),
            _WeekNavigator(
              weekStart: _weekStart,
              isCurrent: _isCurrentWeek,
              onShift: (d) => setState(
                  () => _weekStart = Dates.addDays(_weekStart, d * 7)),
              onThisWeek: () => setState(
                  () => _weekStart = Dates.startOfWeek(Dates.today())),
            ),
            const SizedBox(height: 8),
            _AsyncCard<SummaryStat>(
              value: weekAsync,
              builder: (s) => _WeeklyChartCard(summary: s),
            ),
            const SizedBox(height: 20),
            Text(l10n.last30Days,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _AsyncCard<SummaryStat>(
              value: monthAsync,
              builder: (s) => _MonthlyTrendCard(summary: s),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Hero stat tiles --------------------------------------------------------

class _HeroRow extends StatelessWidget {
  const _HeroRow({required this.streakAsync, required this.weekAsync});
  final AsyncValue<StreakStat> streakAsync;
  final AsyncValue<SummaryStat> weekAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department,
            label: l10n.statStreak,
            value: streakAsync.when(
              data: (s) => '${s.current}',
              loading: () => '—',
              error: (_, _) => '—',
            ),
            sub: streakAsync.maybeWhen(
              data: (s) => l10n.bestStreak(s.longest),
              orElse: () => '',
            ),
            accent: Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.percent,
            label: l10n.statThisWeek,
            value: weekAsync.when(
              data: (s) => '${s.completionPct}%',
              loading: () => '—',
              error: (_, _) => '—',
            ),
            sub: weekAsync.maybeWhen(
              data: (s) => l10n.tasksCompletedRatio(s.totalCompleted, s.totalTasks),
              orElse: () => '',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.emoji_events,
            label: l10n.statGoodDays,
            value: weekAsync.when(
              data: (s) => '${s.successfulDays}',
              loading: () => '—',
              error: (_, _) => '—',
            ),
            sub: weekAsync.maybeWhen(
              data: (s) => l10n.ofActiveDays(s.activeDays),
              orElse: () => '',
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.labelMedium),
            if (sub.isNotEmpty)
              Text(sub,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ---- Async card wrapper -----------------------------------------------------

class _AsyncCard<T> extends StatelessWidget {
  const _AsyncCard({required this.value, required this.builder});
  final AsyncValue<T> value;
  final Widget Function(T) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Card(
        child: SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => Card(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                apiErrorMessage(context.l10n, e,
                    fallback: context.l10n.statsNeedConnection),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      data: builder,
    );
  }
}

// ---- Weekly bar chart -------------------------------------------------------

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.isCurrent,
    required this.onShift,
    required this.onThisWeek,
  });
  final DateTime weekStart;
  final bool isCurrent;
  final void Function(int) onShift;
  final VoidCallback onThisWeek;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dates = DateLabels(l10n);
    final end = Dates.addDays(weekStart, 6);
    return Row(
      children: [
        IconButton(onPressed: () => onShift(-1), icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Center(
            child: Text(l10n.dateRange(dates.short(weekStart), dates.short(end)),
                style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        if (!isCurrent)
          TextButton(onPressed: onThisWeek, child: Text(l10n.thisWeek)),
        IconButton(
          onPressed: isCurrent ? null : () => onShift(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.summary});
  final SummaryStat summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final weekdayHeadings = DateLabels(l10n).weekdayHeadings;
    final days = summary.days; // 7 entries, Mon..Sun

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(l10n.completionByDay,
                  style: theme.textTheme.titleSmall),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItem: (group, _, rod, _) {
                        final d = days[group.x];
                        return BarTooltipItem(
                          '${d.completed}/${d.total} · ${d.completionPct}%',
                          TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) => Text('${value.toInt()}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= weekdayHeadings.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(weekdayHeadings[i],
                                style: theme.textTheme.labelSmall),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: days[i].total == 0
                                ? 0
                                : days[i].completionPct.toDouble(),
                            width: 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            // Emphasis of the single hue: solid when the day met
                            // the goal, a light tint otherwise.
                            color: days[i].successful
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.35),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  _LegendSwatch(
                      color: scheme.primary,
                      label: l10n.metGoal(summary.threshold)),
                  const SizedBox(width: 16),
                  _LegendSwatch(
                      color: scheme.primary.withValues(alpha: 0.35),
                      label: l10n.belowGoal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ---- Monthly trend line -----------------------------------------------------

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.summary});
  final SummaryStat summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = summary.days;

    final spots = [
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].completionPct.toDouble()),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (spots) => spots.map((s) {
                    final d = days[s.x.toInt()];
                    return LineTooltipItem(
                      '${d.date.substring(5)} · ${d.completionPct}%',
                      TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: scheme.outlineVariant, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 25,
                    reservedSize: 32,
                    getTitlesWidget: (value, _) => Text('${value.toInt()}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 7,
                    reservedSize: 24,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(days[i].date.substring(5),
                            style: theme.textTheme.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: scheme.primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
