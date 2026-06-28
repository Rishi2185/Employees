import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/day_key.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_in.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/stat_card.dart';
import '../widgets/animated_counter.dart';
import '../state/dashboard_provider.dart';

/// The reception dashboard: today's tiles + a doctor-wise breakdown.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final dayKey = dash.dayKey;
    final subtitle = dayKey == null
        ? 'Live overview of the clinic'
        : 'Today · ${Fmt.longDate(DayKey.parse(dayKey))}';

    return ScreenScaffold(
      title: 'Dashboard',
      subtitle: subtitle,
      actions: [
        IconButton.filledTonal(
          onPressed: dash.loading ? null : () => dash.load(),
          icon: dash.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      child: dash.error != null && dash.today == null
          ? EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn’t load stats',
              message: dash.error!,
              action: FilledButton(
                onPressed: () => dash.load(),
                child: const Text('Retry'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              children: [
                _Tiles(dash: dash),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Doctor-wise status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FadeIn(
                  delay: const Duration(milliseconds: 200),
                  scaleFrom: 0.98,
                  child: _DoctorBreakdown(stats: dash.doctorStats, loading: dash.loading),
                ),
              ],
            ),
    );
  }
}

class _Tiles extends StatelessWidget {
  final DashboardProvider dash;
  const _Tiles({required this.dash});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      StatCard(
        label: 'Total Patients',
        value: Fmt.compact(dash.totalPatients),
        icon: Icons.groups_rounded,
        accent: AppColors.primary,
      ),
      StatCard(
        label: "Today's Appts",
        value: '${dash.todaysAppointments}',
        icon: Icons.event_available_rounded,
        accent: AppColors.info,
      ),
      StatCard(
        label: 'Completed',
        value: '${dash.completed}',
        icon: Icons.check_circle_rounded,
        accent: AppColors.success,
      ),
      StatCard(
        label: 'Pending',
        value: '${dash.pending}',
        icon: Icons.pending_actions_rounded,
        accent: AppColors.warning,
      ),
      StatCard(
        label: 'Walk-ins',
        value: '${dash.walkIns}',
        icon: Icons.directions_walk_rounded,
        accent: AppColors.accentPurple,
      ),
      StatCard(
        label: 'Cancelled',
        value: '${dash.cancelled}',
        icon: Icons.cancel_rounded,
        accent: AppColors.danger,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 760
                ? 3
                : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < tiles.length; i++)
              SizedBox(
                width: itemWidth,
                height: 115,
                child: FadeIn(
                  delay: Duration(milliseconds: 50 + i * 40),
                  scaleFrom: 0.95,
                  child: tiles[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DoctorBreakdown extends StatelessWidget {
  final List<DoctorStat> stats;
  final bool loading;
  const _DoctorBreakdown({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Center(
          child: Text(
            loading ? 'Fetching doctor statistics…' : 'No appointments scheduled today.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14.5,
            ),
          ),
        ),
      );
    }

    final maxTotal =
        stats.map((s) => s.total).fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _DoctorRow(stat: stats[i], maxTotal: maxTotal),
          ],
        ],
      ),
    );
  }
}

class _DoctorRow extends StatefulWidget {
  final DoctorStat stat;
  final int maxTotal;
  const _DoctorRow({required this.stat, required this.maxTotal});

  @override
  State<_DoctorRow> createState() => _DoctorRowState();
}

class _DoctorRowState extends State<_DoctorRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ratio = (widget.stat.total / widget.maxTotal).clamp(0.0, 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppTheme.fast,
        color: _hovered ? AppColors.primary.withValues(alpha: 0.02) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Avatar(name: widget.stat.doctorName, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.stat.doctorName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress indicator with smooth transition
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: ratio),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: val.isNaN ? 0.0 : val,
                          minHeight: 6,
                          backgroundColor: AppColors.mint,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            _miniStat(widget.stat.completed, 'done', AppColors.success),
            const SizedBox(width: 18),
            _miniStat(widget.stat.pending, 'pending', AppColors.warning),
            const SizedBox(width: 18),
            _miniStat(widget.stat.total, 'total', AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(int value, String label, Color color) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedCounter(
            value: value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
