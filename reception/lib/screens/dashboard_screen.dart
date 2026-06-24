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
                Text('Doctor-wise today',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 18)),
                const SizedBox(height: 14),
                _DoctorBreakdown(stats: dash.doctorStats, loading: dash.loading),
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
        label: "Today's Appointments",
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
                child: FadeIn(delay: Duration(milliseconds: i * 60), child: tiles[i]),
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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            loading ? 'Loading…' : 'No appointments yet today.',
            style: const TextStyle(color: AppColors.textSecondary),
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

class _DoctorRow extends StatelessWidget {
  final DoctorStat stat;
  final int maxTotal;
  const _DoctorRow({required this.stat, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final ratio = (stat.total / maxTotal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Avatar(name: stat.doctorName, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.doctorName,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.mint,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _miniStat('${stat.completed}', 'done', AppColors.success),
          const SizedBox(width: 16),
          _miniStat('${stat.pending}', 'pending', AppColors.warning),
          const SizedBox(width: 16),
          _miniStat('${stat.total}', 'total', AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }
}
