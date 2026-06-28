import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/day_state.dart';
import '../services/eod_service.dart';
import '../state/dashboard_provider.dart';
import '../state/eod_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/day_key.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/fade_in.dart';

/// The end-of-day console: shows which past days still need processing, runs
/// the archive → summarize → purge job with a live log, and lists the history
/// of completed days with retry for any that failed.
class EodScreen extends StatefulWidget {
  const EodScreen({super.key});

  @override
  State<EodScreen> createState() => _EodScreenState();
}

class _EodScreenState extends State<EodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final dash = context.read<DashboardProvider>();
    if (dash.dayKey == null) await dash.load();
    final today = dash.dayKey;
    if (today != null && mounted) {
      await context.read<EodProvider>().refresh(today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eod = context.watch<EodProvider>();

    return ScreenScaffold(
      title: 'End of day console',
      subtitle: 'Perform secure archiving, summary calculations, and database purge operations',
      actions: [
        IconButton.filledTonal(
          onPressed: eod.isRunning ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 50),
            scaleFrom: 0.98,
            child: _RunCard(eod: eod, onRun: () => eod.runAll()),
          ),
          if (eod.log.isNotEmpty) ...[
            const SizedBox(height: 20),
            FadeIn(
              delay: const Duration(milliseconds: 100),
              offsetY: 15,
              child: _LogPanel(eod: eod),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Archive History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FadeIn(
            delay: const Duration(milliseconds: 150),
            scaleFrom: 0.98,
            child: _History(eod: eod),
          ),
        ],
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  final EodProvider eod;
  final VoidCallback onRun;
  const _RunCard({required this.eod, required this.onRun});

  @override
  Widget build(BuildContext context) {
    final pending = eod.eligibleDays;
    final hasPending = pending.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: hasPending
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.mint.withValues(alpha: 0.35),
                  AppColors.mint.withValues(alpha: 0.15),
                ],
              )
            : const LinearGradient(colors: [AppColors.white, AppColors.white]),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: hasPending ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (hasPending ? AppColors.warning : AppColors.success)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPending ? Icons.pending_actions_rounded : Icons.verified_rounded,
              color: hasPending ? AppColors.warning : AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending
                      ? '${pending.length} day(s) ready for archive process'
                      : 'All clinic archives up-to-date',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPending
                      ? 'Target days: ${pending.map((d) => Fmt.shortDate(DayKey.parse(d))).join(', ')}'
                      : 'No past-day records are waiting in the cloud.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (eod.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    eod.error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 200,
            child: PrimaryButton(
              label: eod.isRunning ? 'Executing…' : 'Run end-of-day',
              icon: Icons.play_arrow_rounded,
              loading: eod.isRunning,
              onPressed: (!hasPending || eod.isRunning) ? null : onRun,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  final EodProvider eod;
  const _LogPanel({required this.eod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B15),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal_rounded,
                  color: AppColors.primaryLight, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Process output log',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (!eod.isRunning)
                TextButton(
                  onPressed: eod.clearLog,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                  ),
                  child: const Text('Clear Log', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              children: eod.log.map((p) => _logLine(p)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logLine(EodProgress p) {
    final color = p.isError
        ? AppColors.danger
        : p.stage == EodStage.purged
            ? AppColors.primaryLight
            : Colors.white70;
    final icon = p.isError
        ? Icons.error_outline_rounded
        : switch (p.stage) {
            EodStage.archived => Icons.save_alt_rounded,
            EodStage.summarized => Icons.summarize_rounded,
            EodStage.purged => Icons.cloud_done_rounded,
            EodStage.pending => Icons.hourglass_empty_rounded,
          };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            '[${p.dayKey}]',
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              p.message,
              style: TextStyle(
                color: color,
                fontFamily: 'Courier',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  final EodProvider eod;
  const _History({required this.eod});

  @override
  Widget build(BuildContext context) {
    if (eod.history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: const EmptyState(
          icon: Icons.history_rounded,
          title: 'No past archives recorded',
          message: 'Historical end-of-day processes will appear here.',
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
          for (var i = 0; i < eod.history.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _HistoryRow(
              state: eod.history[i],
              running: eod.isRunning,
              onRetry: () => eod.runDay(eod.history[i].dayKey),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  final DayState state;
  final bool running;
  final VoidCallback onRetry;
  const _HistoryRow({
    required this.state,
    required this.running,
    required this.onRetry,
  });

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final done = widget.state.isDone;
    final color = done
        ? AppColors.success
        : widget.state.lastError != null
            ? AppColors.danger
            : AppColors.warning;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppTheme.fast,
        color: _hovered ? AppColors.primary.withValues(alpha: 0.02) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.longDate(DayKey.parse(widget.state.dayKey)),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(widget.state),
                    style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            _StageChips(stage: widget.state.stage),
            if (!done) ...[
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: widget.running ? null : widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Resume', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(DayState s) {
    if (s.lastError != null && !s.isDone) return 'Execution failure: ${s.lastError}';
    if (s.isDone) {
      return 'Archived ${s.archivedCount} records · Purged ${s.purgedCount} from database';
    }
    return 'Active stage: ${s.stage.name}';
  }
}

class _StageChips extends StatelessWidget {
  final EodStage stage;
  const _StageChips({required this.stage});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, EodStage s) {
      final reached = stage.reached(s);
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: reached
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: reached ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('Archive', EodStage.archived),
        chip('Summary', EodStage.summarized),
        chip('Purge', EodStage.purged),
      ],
    );
  }
}
