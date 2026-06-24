import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../state/doctors_provider.dart';
import '../state/trends_provider.dart';

/// Historical trends from the cloud Daily Summaries store — overall or per
/// doctor, over a selectable window, with aggregate tiles and a daily chart.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrendsProvider>().load();
      context.read<DoctorsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trends = context.watch<TrendsProvider>();

    return RefreshIndicator(
      onRefresh: () => trends.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _Filters(trends: trends),
          const SizedBox(height: 18),
          if (trends.error != null && trends.isEmpty)
            _errorBox(trends)
          else ...[
            _aggregateTiles(trends),
            const SizedBox(height: 20),
            _chartCard(context, trends),
          ],
        ],
      ),
    );
  }

  Widget _errorBox(TrendsProvider trends) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load trends',
          message: trends.error!,
          action: FilledButton(
              onPressed: () => trends.load(), child: const Text('Retry')),
        ),
      );

  Widget _aggregateTiles(TrendsProvider trends) {
    final tiles = [
      StatCard(
          label: 'Total appointments',
          value: Fmt.compact(trends.totalAppointments),
          icon: Icons.summarize_rounded,
          accent: AppColors.primary),
      StatCard(
          label: 'Completed',
          value: Fmt.compact(trends.totalCompleted),
          icon: Icons.check_circle_rounded,
          accent: AppColors.success),
      StatCard(
          label: 'Avg / day',
          value: trends.avgPerDay.toStringAsFixed(1),
          icon: Icons.trending_up_rounded,
          accent: AppColors.info),
      StatCard(
          label: 'Peak / day',
          value: '${trends.peakDay}',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.warning),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: tiles,
    );
  }

  Widget _chartCard(BuildContext context, TrendsProvider trends) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Text(
                  trends.doctorId == null
                      ? 'All doctors'
                      : (trends.doctorName ?? 'Doctor'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                _legendDot(AppColors.primary, 'Total'),
                const SizedBox(width: 10),
                _legendDot(AppColors.success, 'Completed'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: trends.loading && trends.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : trends.isEmpty
                    ? const Center(
                        child: Text('No summaries in this range yet.',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : _TrendChart(trends: trends),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  final TrendsProvider trends;
  const _Filters({required this.trends});

  @override
  Widget build(BuildContext context) {
    final doctors = context.watch<DoctorsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range segmented control
        SegmentedButton<TrendRange>(
          segments: const [
            ButtonSegment(value: TrendRange.week, label: Text('7d')),
            ButtonSegment(value: TrendRange.month, label: Text('30d')),
            ButtonSegment(value: TrendRange.quarter, label: Text('90d')),
          ],
          selected: {trends.range},
          onSelectionChanged: (s) => trends.setRange(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 12),
        // Doctor dropdown (overall + each doctor)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: trends.doctorId,
              hint: const Text('All doctors'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All doctors (overall)')),
                ...doctors.all.map((d) => DropdownMenuItem<String?>(
                      value: d.id,
                      child: Text(d.name, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (id) => trends.setDoctor(id,
                  doctorName: id == null ? null : doctors.byId(id)?.name),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final TrendsProvider trends;
  const _TrendChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final points = trends.points;
    final totalSpots = <FlSpot>[];
    final doneSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      totalSpots.add(FlSpot(i.toDouble(), points[i].total.toDouble()));
      doneSpots.add(FlSpot(i.toDouble(), points[i].completed.toDouble()));
    }

    final maxY = (trends.peakDay == 0 ? 4 : trends.peakDay).toDouble();
    final labelEvery = (points.length / 4).ceil().clamp(1, points.length);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + (maxY * 0.15).ceilToDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textTertiary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                if (i % labelEvery != 0 && i != points.length - 1) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(Fmt.shortDate(points[i].date).substring(5),
                      style: const TextStyle(
                          fontSize: 9.5, color: AppColors.textTertiary)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            getTooltipItems: (spots) => spots.map((s) {
              final p = points[s.x.toInt()];
              final isTotal = s.barIndex == 0;
              return LineTooltipItem(
                '${isTotal ? 'Total' : 'Done'}: ${s.y.toInt()}\n${Fmt.shortDate(p.date)}',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          _bar(totalSpots, AppColors.primary, fill: true),
          _bar(doneSpots, AppColors.success),
        ],
      ),
    );
  }

  LineChartBarData _bar(List<FlSpot> spots, Color color, {bool fill = false}) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.25,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: fill,
          color: color.withValues(alpha: 0.10),
        ),
      );
}
