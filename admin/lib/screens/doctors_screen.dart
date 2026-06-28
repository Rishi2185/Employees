import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_in.dart';
import '../state/doctors_provider.dart';
import 'doctor_edit_screen.dart';

/// The doctor roster manager: search, show/hide inactive, edit existing, add
/// new. Every write flows to the cloud and reflects in the patient app.
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorsProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openEditor({Doctor? doctor}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DoctorEditScreen(doctor: doctor),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorsProvider>();
    final list = provider.filtered;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add doctor',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _search,
                onChanged: provider.setQuery,
                decoration: const InputDecoration(
                  hintText: 'Search doctors…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  '${provider.activeCount} active · ${provider.inactiveCount} inactive',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Show inactive',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: provider.includeInactive,
                    onChanged: (v) => provider.toggleIncludeInactive(v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading && provider.all.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : provider.error != null && provider.all.isEmpty
                    ? EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Couldn’t load doctors',
                        message: provider.error!,
                        action: FilledButton(
                            onPressed: () => provider.load(force: true),
                            child: const Text('Retry')),
                      )
                    : list.isEmpty
                        ? const EmptyState(
                            icon: Icons.badge_outlined,
                            title: 'No doctors found',
                            message: 'Try a different search or add a new doctor.',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.load(force: true),
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => FadeIn(
                                delay: Duration(milliseconds: (i % 8) * 40),
                                scaleFrom: 0.96,
                                child: _DoctorCard(
                                  doctor: list[i],
                                  onEdit: () => _openEditor(doctor: list[i]),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatefulWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  const _DoctorCard({required this.doctor, required this.onEdit});

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DoctorsProvider>();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: AppTheme.fast,
        curve: AppTheme.curve,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: AppTheme.curve,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.border,
            ),
            boxShadow: _hovered ? AppColors.hoverGlow : AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              onTap: widget.onEdit,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Opacity(
                      opacity: widget.doctor.active ? 1 : 0.55,
                      child: Avatar(
                        name: widget.doctor.name,
                        imageUrl: widget.doctor.photoUrl,
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.doctor.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: widget.doctor.active
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!widget.doctor.active)
                                _badge('Inactive', AppColors.textTertiary, null)
                              else if (widget.doctor.availableToday)
                                _badge('In today', AppColors.success, _pulseController),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.doctor.specialtyName} · ₹${widget.doctor.consultationFee}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.doctor.experienceYears} yrs experience'
                            '${widget.doctor.qualifications.isNotEmpty ? ' · ${widget.doctor.qualifications}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _menu(context, provider),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, AnimationController? pulse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse != null) ...[
            AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + 0.7 * (1.0 - pulse.value),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, DoctorsProvider provider) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary),
      onSelected: (v) async {
        if (v == 'edit') {
          widget.onEdit();
        } else if (v == 'deactivate') {
          final ok = await _confirmDeactivate(context);
          if (ok == true) {
            final done = await provider.deactivate(widget.doctor.id);
            if (context.mounted) {
              _snack(context,
                  done ? '${widget.doctor.name} deactivated.' : provider.error ?? 'Failed.');
            }
          }
        } else if (v == 'reactivate') {
          final res = await provider.reactivate(widget.doctor.id);
          if (context.mounted) {
            _snack(context,
                res != null ? '${widget.doctor.name} reactivated.' : provider.error ?? 'Failed.');
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit details')),
        if (widget.doctor.active)
          const PopupMenuItem(
              value: 'deactivate', child: Text('Deactivate doctor'))
        else
          const PopupMenuItem(
              value: 'reactivate', child: Text('Reactivate doctor')),
      ],
    );
  }

  Future<bool?> _confirmDeactivate(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Deactivate ${widget.doctor.name}?'),
          content: const Text(
              'The doctor will be hidden from the patient app. Past appointments '
              'keep their name. You can reactivate them any time.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
