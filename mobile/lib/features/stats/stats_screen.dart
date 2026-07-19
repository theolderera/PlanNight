import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/api/api_error.dart';
import '../../data/models/stats.dart';
import 'stats_providers.dart';

/// Progress — the discipline dashboard. A streak/week/good-days hero row, a
/// weekly completion bar chart, and a 30-day trend line. Charts are single-hue
/// (the cobalt accent); a met-goal day is the solid hue, below-goal a tint.
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
    final theme = Theme.of(context);
    final weekAsync = ref.watch(summaryProvider(_weekRange));
    final monthAsync = ref.watch(summaryProvider(_monthRange));
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colors.accent,
          onRefresh: () async {
            ref.invalidate(summaryProvider);
            ref.invalidate(streakProvider);
            await ref.read(summaryProvider(_weekRange).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Text(l10n.progressTitle, style: theme.textTheme.displaySmall),
              const SizedBox(height: 18),
              _HeroTiles(streakAsync: streakAsync, weekAsync: weekAsync),
              const SizedBox(height: 20),
              _WeekNavigator(
                weekStart: _weekStart,
                isCurrent: _isCurrentWeek,
                onShift: (d) => setState(
                    () => _weekStart = Dates.addDays(_weekStart, d * 7)),
                onThisWeek: () => setState(
                    () => _weekStart = Dates.startOfWeek(Dates.today())),
              ),
              const SizedBox(height: 10),
              _AsyncCard<SummaryStat>(
                value: weekAsync,
                builder: (s) => _WeeklyChartCard(summary: s),
              ),
              const SizedBox(height: 22),
              Text(l10n.last30Days, style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _AsyncCard<SummaryStat>(
                value: monthAsync,
                builder: (s) => _MonthlyTrendCard(summary: s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Hero stat tiles --------------------------------------------------------

class _HeroTiles extends StatelessWidget {
  const _HeroTiles({required this.streakAsync, required this.weekAsync});
  final AsyncValue<StreakStat> streakAsync;
  final AsyncValue<SummaryStat> weekAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Streak — the emphasis tile, warm gradient.
        Expanded(
          child: _GradientTile(
            value: streakAsync.maybeWhen(data: (s) => '${s.current}', orElse: () => '—'),
            label: l10n.statStreak,
            icon: Icons.local_fire_department_rounded,
            start: c.streakStart,
            end: c.streakEnd,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _PlainTile(
            value: weekAsync.maybeWhen(data: (s) => '${s.completionPct}%', orElse: () => '—'),
            label: l10n.statThisWeek,
            valueColor: c.accent,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: _PlainTile(
            valueRich: weekAsync.maybeWhen(
              data: (s) => (main: '${s.successfulDays}', sub: '/${s.activeDays}'),
              orElse: () => (main: '—', sub: ''),
            ),
            label: l10n.statGoodDays,
            valueColor: c.success,
          ),
        ),
      ],
    );
  }
}

class _GradientTile extends StatelessWidget {
  const _GradientTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.start,
    required this.end,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: end.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontFamily: AppFonts.mono, fontSize: 27, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: AppFonts.sans, fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _PlainTile extends StatelessWidget {
  const _PlainTile({this.value, this.valueRich, required this.label, required this.valueColor})
      : assert(value != null || valueRich != null);
  final String? value;
  final ({String main, String sub})? valueRich;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 2), spreadRadius: -4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value ?? valueRich!.main,
              style: TextStyle(fontFamily: AppFonts.mono, fontSize: 27, fontWeight: FontWeight.w800, color: valueColor, height: 1),
              children: valueRich != null && valueRich!.sub.isNotEmpty
                  ? [TextSpan(text: valueRich!.sub, style: TextStyle(fontSize: 15, color: c.textFaint))]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted)),
        ],
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
    final c = context.colors;
    return value.when(
      loading: () => _shell(c, const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => _shell(
        c,
        SizedBox(
          height: 150,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                apiErrorMessage(context.l10n, e, fallback: context.l10n.statsNeedConnection),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
      data: builder,
    );
  }

  Widget _shell(AppColors c, Widget child) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 2), spreadRadius: -4)],
        ),
        child: child,
      );
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
    final c = context.colors;
    final dates = DateLabels(l10n);
    final end = Dates.addDays(weekStart, 6);
    return Row(
      children: [
        IconButton(
          onPressed: () => onShift(-1),
          icon: const Icon(Icons.chevron_left_rounded),
          color: c.textSecondary,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Center(
            child: Text(l10n.dateRange(dates.short(weekStart), dates.short(end)),
                style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        if (!isCurrent)
          TextButton(onPressed: onThisWeek, child: Text(l10n.thisWeek))
        else
          const SizedBox(width: 8),
        IconButton(
          onPressed: isCurrent ? null : () => onShift(1),
          icon: const Icon(Icons.chevron_right_rounded),
          color: c.textSecondary,
          visualDensity: VisualDensity.compact,
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
    final c = context.colors;
    final l10n = context.l10n;
    final weekdayHeadings = DateLabels(l10n).weekdayHeadings;
    final days = summary.days; // 7 entries, Mon..Sun

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 2), spreadRadius: -4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(l10n.completionByDay, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 18),
          if (summary.totalTasks == 0)
            const _EmptyChart()
          else ...[
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => c.navy,
                    getTooltipItem: (group, _, rod, _) {
                      final d = days[group.x];
                      return BarTooltipItem(
                        '${d.completed}/${d.total} · ${d.completionPct}%',
                        TextStyle(color: c.onNavy, fontSize: 12, fontFamily: AppFonts.sans, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(color: c.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text('${value.toInt()}',
                          style: TextStyle(fontFamily: AppFonts.mono, fontSize: 10, color: c.textFaint)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= weekdayHeadings.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(weekdayHeadings[i],
                              style: TextStyle(fontFamily: AppFonts.sans, fontSize: 10, fontWeight: FontWeight.w600, color: c.textMuted)),
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
                          toY: days[i].total == 0 ? 0 : days[i].completionPct.toDouble(),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          color: days[i].successful ? c.accent : c.accent.withValues(alpha: 0.32),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true, toY: 100, color: c.trackBg,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                _LegendSwatch(color: c.accent, label: l10n.metGoal(summary.threshold)),
                const SizedBox(width: 16),
                _LegendSwatch(color: c.accent.withValues(alpha: 0.32), label: l10n.belowGoal),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}

/// Shown inside a chart card when the range has no tasks at all, so an empty
/// chart never reads as "broken".
class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return SizedBox(
      height: 170,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 34, color: c.textFaint),
            const SizedBox(height: 12),
            Text(l10n.statsNoData,
                style: TextStyle(fontFamily: AppFonts.sans, fontSize: 14, fontWeight: FontWeight.w700, color: c.textSecondary)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.statsNoDataHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppFonts.sans, fontSize: 12, fontWeight: FontWeight.w500, color: c.textMuted)),
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
          width: 11, height: 11,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontFamily: AppFonts.sans, fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textMuted)),
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
    final c = context.colors;
    final days = summary.days;
    final spots = [
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].completionPct.toDouble()),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 2), spreadRadius: -4)],
      ),
      child: summary.totalTasks == 0
          ? const _EmptyChart()
          : SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => c.navy,
                getTooltipItems: (spots) => spots.map((s) {
                  final d = days[s.x.toInt()];
                  return LineTooltipItem(
                    '${d.date.substring(5)} · ${d.completionPct}%',
                    TextStyle(color: c.onNavy, fontSize: 12, fontFamily: AppFonts.sans, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => FlLine(color: c.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 25,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) => Text('${value.toInt()}',
                      style: TextStyle(fontFamily: AppFonts.mono, fontSize: 10, color: c.textFaint)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 7,
                  reservedSize: 22,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(days[i].date.substring(5),
                          style: TextStyle(fontFamily: AppFonts.mono, fontSize: 9.5, color: c.textMuted)),
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
                color: c.accent,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.accent.withValues(alpha: 0.22), c.accent.withValues(alpha: 0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
