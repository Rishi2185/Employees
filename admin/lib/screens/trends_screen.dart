import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/fade_in.dart';
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

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        onRefresh: () => trends.load(),
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            FadeIn(
              delay: const Duration(milliseconds: 50),
              offsetY: -10,
              child: _Filters(trends: trends),
            ),
            const SizedBox(height: 20),
            if (trends.error != null && trends.isEmpty)
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: _errorBox(trends),
              )
            else ...[
              _aggregateTiles(trends),
              const SizedBox(height: 20),
              FadeIn(
                delay: const Duration(milliseconds: 250),
                scaleFrom: 0.98,
                child: _chartCard(context, trends),
              ),
            ],
          ],
        ),
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
          label: 'Total Appts',
          value: Fmt.compact(trends.totalAppointments),
          icon: Icons.analytics_rounded,
          accent: AppColors.primary),
      StatCard(
          label: 'Completed',
          value: Fmt.compact(trends.totalCompleted),
          icon: Icons.check_circle_rounded,
          accent: AppColors.success),
      StatCard(
          label: 'Avg / Day',
          value: trends.avgPerDay.toStringAsFixed(1),
          icon: Icons.trending_up_rounded,
          accent: AppColors.info),
      StatCard(
          label: 'Peak / Day',
          value: '${trends.peakDay}',
          icon: Icons.bolt_rounded,
          accent: AppColors.warning),
    ];
    final isWide = MediaQuery.of(context).size.width > 600;
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: isWide ? 1.35 : 1.30,
      children: [
        for (var i = 0; i < tiles.length; i++)
          FadeIn(
            delay: Duration(milliseconds: 100 + i * 50),
            scaleFrom: 0.95,
            child: tiles[i],
          ),
      ],
    );
  }

  Widget _chartCard(BuildContext context, TrendsProvider trends) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      trends.doctorId == null ? Icons.business_center_rounded : Icons.person_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trends.doctorId == null
                            ? 'All Doctors (overall)'
                            : (trends.doctorName ?? 'Doctor'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 26), // Align with start of title text (18 icon + 8 spacing)
                    _legendDot(AppColors.primary, 'Total'),
                    const SizedBox(width: 12),
                    _legendDot(AppColors.success, 'Completed'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: trends.loading && trends.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : trends.isEmpty
                    ? const Center(
                        child: Text(
                          'No summaries in this range yet.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      )
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
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
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TrendRange>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: AppColors.white,
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
            ),
            segments: const [
              ButtonSegment(
                value: TrendRange.week,
                label: Text('7 days', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              ButtonSegment(
                value: TrendRange.month,
                label: Text('30 days', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              ButtonSegment(
                value: TrendRange.quarter,
                label: Text('90 days', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
            selected: {trends.range},
            onSelectionChanged: (s) => trends.setRange(s.first),
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 12),
        // Doctor dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: trends.doctorId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              hint: const Text('All doctors'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'All doctors (overall)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                ...doctors.all.map((d) => DropdownMenuItem<String?>(
                      value: d.id,
                      child: Text(
                        d.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
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

    final peak = (trends.peakDay == 0 ? 4 : trends.peakDay).toDouble();
    final interval = (peak / 4).ceilToDouble().clamp(1.0, double.infinity).toDouble();
    final targetMax = peak + (peak * 0.15).ceilToDouble();
    final maxY = ((targetMax / interval).ceil() * interval).toDouble();
    final labelEvery = (points.length / 4).ceil().clamp(1, points.length);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (v, meta) => Text(
                '${v.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
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
                  child: Text(
                    Fmt.shortDate(points[i].date).substring(5),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
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
                '${isTotal ? 'Total' : 'Completed'}: ${s.y.toInt()}\n${Fmt.shortDate(p.date)}',
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          _bar(
            spots: totalSpots,
            color: AppColors.primary,
            gradientColors: [AppColors.primaryLight, AppColors.primary],
            fill: true,
          ),
          _bar(
            spots: doneSpots,
            color: AppColors.success,
            gradientColors: [AppColors.primaryBright, AppColors.success],
          ),
        ],
      ),
    );
  }

  LineChartBarData _bar({
    required List<FlSpot> spots,
    required Color color,
    required List<Color> gradientColors,
    bool fill = false,
  }) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.25,
        gradient: LinearGradient(colors: gradientColors),
        barWidth: 3.2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: fill,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.01),
            ],
          ),
        ),
      );
}
