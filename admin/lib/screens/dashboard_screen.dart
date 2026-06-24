import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/day_key.dart';
import '../utils/formatters.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_in.dart';
import '../widgets/stat_card.dart';
import '../state/live_stats_provider.dart';

/// The live overview: today's counts (from the Appointments store) + the
/// per-doctor attended-vs-remaining breakdown + a count of future bookings.
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
      context.read<LiveStatsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveStatsProvider>();

    if (live.error != null && live.stats == null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load live stats',
        message: live.error!,
        action: FilledButton(
            onPressed: () => live.load(), child: const Text('Retry')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => live.load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _header(context, live),
          const SizedBox(height: 20),
          _tiles(live),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Doctor load — today',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18)),
              const Spacer(),
              if (live.loading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 14),
          _doctorLoad(live),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, LiveStatsProvider live) {
    final dayKey = live.dayKey;
    final subtitle = dayKey == null
        ? 'Live activity across the hospital'
        : 'Today · ${Fmt.longDate(DayKey.parse(dayKey))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: _headerStat('Attended', '${live.stats?.attended ?? 0}',
                    Icons.task_alt_rounded),
              ),
              Container(width: 1, height: 42, color: Colors.white24),
              Expanded(
                child: _headerStat('Remaining', '${live.stats?.remaining ?? 0}',
                    Icons.timelapse_rounded),
              ),
              Container(width: 1, height: 42, color: Colors.white24),
              Expanded(
                child: _headerStat(
                    'Upcoming', '${live.futureUpcoming}', Icons.event_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
      ],
    );
  }

  Widget _tiles(LiveStatsProvider live) {
    final t = live.today;
    final tiles = [
      StatCard(
          label: "Today's Appointments",
          value: '${t.todaysAppointments}',
          icon: Icons.event_available_rounded,
          accent: AppColors.info),
      StatCard(
          label: 'Completed',
          value: '${t.completed}',
          icon: Icons.check_circle_rounded,
          accent: AppColors.success),
      StatCard(
          label: 'Pending',
          value: '${t.pending}',
          icon: Icons.pending_actions_rounded,
          accent: AppColors.warning),
      StatCard(
          label: 'Cancelled',
          value: '${t.cancelled}',
          icon: Icons.cancel_rounded,
          accent: AppColors.danger),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        for (var i = 0; i < tiles.length; i++)
          FadeIn(delay: Duration(milliseconds: i * 60), child: tiles[i]),
      ],
    );
  }

  Widget _doctorLoad(LiveStatsProvider live) {
    final list = live.byLoad;
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(live.loading ? 'Loading…' : 'No appointments yet today.',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _DoctorLoadRow(stat: list[i]),
          ],
        ],
      ),
    );
  }
}

class _DoctorLoadRow extends StatelessWidget {
  final DoctorLiveStat stat;
  const _DoctorLoadRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Avatar(name: stat.doctorName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stat.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.mint,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stat.completed} done · ${stat.pending} pending'
                  '${stat.cancelled > 0 ? ' · ${stat.cancelled} cancelled' : ''}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text('${stat.total}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const Text('total',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
