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
import '../widgets/animated_counter.dart';
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        onRefresh: () => live.load(),
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Greeting row
            FadeIn(
              delay: const Duration(milliseconds: 50),
              offsetY: -10,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()}, Admin',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        live.dayKey == null
                            ? 'Hospital Live Feed'
                            : 'Today · ${Fmt.longDate(DayKey.parse(live.dayKey!))}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (live.loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  else
                    IconButton.filledTonal(
                      onPressed: () => live.load(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Header Hero Banner with gradients and animated counters
            FadeIn(
              delay: const Duration(milliseconds: 100),
              scaleFrom: 0.96,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _headerStat(
                        'Attended',
                        live.stats?.attended ?? 0,
                        Icons.check_circle_outline_rounded,
                        const Color(0xFF5CC08A),
                      ),
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    Expanded(
                      child: _headerStat(
                        'Remaining',
                        live.stats?.remaining ?? 0,
                        Icons.hourglass_empty_rounded,
                        const Color(0xFFF5A623),
                      ),
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    Expanded(
                      child: _headerStat(
                        'Upcoming',
                        live.futureUpcoming,
                        Icons.date_range_rounded,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid cards
            _tiles(live),
            const SizedBox(height: 28),

            // Section: Doctor load
            FadeIn(
              delay: const Duration(milliseconds: 250),
              offsetY: 15,
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Doctor load — today',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FadeIn(
              delay: const Duration(milliseconds: 300),
              scaleFrom: 0.98,
              child: _doctorLoad(live),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, int value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        AnimatedCounter(
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _tiles(LiveStatsProvider live) {
    final t = live.today;
    final tiles = [
      StatCard(
          label: "Today's Appts",
          value: '${t.todaysAppointments}',
          icon: Icons.event_note_rounded,
          accent: AppColors.info),
      StatCard(
          label: 'Completed',
          value: '${t.completed}',
          icon: Icons.check_circle_rounded,
          accent: AppColors.success),
      StatCard(
          label: 'Pending',
          value: '${t.pending}',
          icon: Icons.pending_rounded,
          accent: AppColors.warning),
      StatCard(
          label: 'Cancelled',
          value: '${t.cancelled}',
          icon: Icons.cancel_rounded,
          accent: AppColors.danger),
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
            delay: Duration(milliseconds: 120 + i * 50),
            scaleFrom: 0.95,
            child: tiles[i],
          ),
      ],
    );
  }

  Widget _doctorLoad(LiveStatsProvider live) {
    final list = live.byLoad;
    if (list.isEmpty) {
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
            live.loading ? 'Fetching load stats…' : 'No appointments scheduled today.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Avatar(name: stat.doctorName, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Smooth Tween animation for progress bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: stat.progress),
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
                const SizedBox(height: 4),
                Text(
                  '${stat.completed} done · ${stat.pending} pending'
                  '${stat.cancelled > 0 ? ' · ${stat.cancelled} cancelled' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedCounter(
                value: stat.total,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
