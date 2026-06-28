import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reception_appointment.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/status_ui.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/fade_in.dart';
import '../state/appointments_provider.dart';
import 'appointment_detail_sheet.dart';

/// The live appointments list — today's queue by default, with search, status
/// and scope filters, plus quick check-in / complete actions per row.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsProvider>().refresh();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 300) {
        context.read<AppointmentsProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appts = context.watch<AppointmentsProvider>();

    return ScreenScaffold(
      title: 'Appointments',
      subtitle: '${appts.total} scheduled',
      actions: [
        IconButton.filledTonal(
          onPressed: appts.loading ? null : () => appts.refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        children: [
          FadeIn(
            delay: const Duration(milliseconds: 50),
            offsetY: -10,
            child: _FilterBar(searchCtrl: _searchCtrl, appts: appts),
          ),
          const SizedBox(height: 12),
          Expanded(child: _list(appts)),
        ],
      ),
    );
  }

  Widget _list(AppointmentsProvider appts) {
    if (appts.loading && appts.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (appts.error != null && appts.items.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load appointments',
        message: appts.error!,
        action: FilledButton(
            onPressed: () => appts.refresh(), child: const Text('Retry')),
      );
    }
    if (appts.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No appointments found',
        message: 'No entries match the active criteria.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => appts.refresh(),
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
        itemCount: appts.items.length + (appts.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i >= appts.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final a = appts.items[i];
          return FadeIn(
            delay: Duration(milliseconds: (i % 8) * 35),
            scaleFrom: 0.97,
            child: AppointmentTile(
              appt: a,
              showDate: appts.scope != ApptScope.today,
              onTap: () => _openDetail(context, a),
              trailing: _quickActions(context, appts, a),
            ),
          );
        },
      ),
    );
  }

  Widget? _quickActions(
      BuildContext context, AppointmentsProvider appts, ReceptionAppointment a) {
    if (a.isCancelled) return null;
    if (!a.isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!a.checkedIn)
            _MiniAction(
              icon: Icons.how_to_reg_rounded,
              tooltip: 'Check in patient',
              color: AppColors.info,
              onTap: () => appts.checkIn(a.id),
            ),
          const SizedBox(width: 8),
          _MiniAction(
            icon: Icons.check_rounded,
            tooltip: 'Mark completed',
            color: AppColors.success,
            onTap: () => appts.markCompleted(a.id),
          ),
        ],
      );
    }
    return null;
  }

  void _openDetail(BuildContext context, ReceptionAppointment a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppointmentDetailSheet(appointmentId: a.id, initial: a),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final AppointmentsProvider appts;
  const _FilterBar({required this.searchCtrl, required this.appts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: appts.setQuery,
                    decoration: const InputDecoration(
                      hintText: 'Search patient name, phone number, or doctor…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SegmentedButton<ApptScope>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: AppColors.white,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                ),
                segments: const [
                  ButtonSegment(
                      value: ApptScope.today,
                      label: Text('Today', style: TextStyle(fontWeight: FontWeight.w700)),
                      icon: Icon(Icons.today_rounded, size: 16)),
                  ButtonSegment(
                      value: ApptScope.upcoming,
                      label: Text('Upcoming', style: TextStyle(fontWeight: FontWeight.w700)),
                      icon: Icon(Icons.upcoming_rounded, size: 16)),
                ],
                selected: {
                  appts.scope == ApptScope.byDate
                      ? ApptScope.today
                      : appts.scope
                },
                onSelectionChanged: (s) => appts.setScope(s.first),
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'All status',
                  selected: appts.statusFilter == null && appts.checkedIn != true,
                  onTap: () {
                    appts.setStatus(null);
                    if (appts.checkedIn == true) appts.setCheckedIn(null);
                  },
                ),
                _StatusChip(
                  label: 'Upcoming',
                  color: AppColors.info,
                  selected: appts.statusFilter == StatusUi.upcoming,
                  onTap: () {
                    appts.setStatus(StatusUi.upcoming);
                    if (appts.checkedIn == true) appts.setCheckedIn(null);
                  },
                ),
                _StatusChip(
                  label: 'Checked-in',
                  color: AppColors.primary,
                  selected: appts.checkedIn == true,
                  onTap: () {
                    appts.setStatus(null);
                    appts.setCheckedIn(true);
                  },
                ),
                _StatusChip(
                  label: 'Completed',
                  color: AppColors.success,
                  selected: appts.statusFilter == StatusUi.completed,
                  onTap: () {
                    appts.setStatus(StatusUi.completed);
                    if (appts.checkedIn == true) appts.setCheckedIn(null);
                  },
                ),
                _StatusChip(
                  label: 'Cancelled',
                  color: AppColors.danger,
                  selected: appts.statusFilter == StatusUi.cancelled,
                  onTap: () {
                    appts.setStatus(StatusUi.cancelled);
                    if (appts.checkedIn == true) appts.setCheckedIn(null);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fast,
        curve: AppTheme.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MiniAction> createState() => _MiniActionState();
}

class _MiniActionState extends State<_MiniAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _hovered ? 1.15 : 1.0,
          duration: AppTheme.fast,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: AppTheme.fast,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(widget.icon, size: 16, color: _hovered ? AppColors.white : widget.color),
            ),
          ),
        ),
      ),
    );
  }

  Color get selectedColor {
    if (_hovered) return widget.color;
    return widget.color.withValues(alpha: 0.10);
  }
}
