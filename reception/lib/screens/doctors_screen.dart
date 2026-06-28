import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_in.dart';
import '../widgets/screen_scaffold.dart';
import '../state/doctors_provider.dart';

/// Read-only doctor directory for checking availability and consult details.
/// (Editing the roster is the admin app's job.)
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorsProvider>();
    final list = provider.filtered;

    return ScreenScaffold(
      title: 'Doctors',
      subtitle: '${provider.doctors.length} rostered',
      actions: [
        IconButton.filledTonal(
          onPressed:
              provider.loading ? null : () => provider.load(force: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                controller: _search,
                onChanged: provider.setQuery,
                decoration: const InputDecoration(
                  hintText: 'Search by doctor name or specialty…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: provider.loading && provider.doctors.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : list.isEmpty
                    ? const EmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No doctors found',
                        message: 'No entries match your search criteria.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 440,
                          mainAxisExtent: 140,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) => FadeIn(
                          delay: Duration(milliseconds: (i % 12) * 35),
                          scaleFrom: 0.96,
                          child: _DoctorCard(doctor: list[i]),
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
  const _DoctorCard({required this.doctor});

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
          padding: const EdgeInsets.all(16),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(name: widget.doctor.name, imageUrl: widget.doctor.photoUrl, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.doctor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.doctor.availableToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: 0.3 + 0.7 * (1.0 - _pulseController.value),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'In today',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.doctor.specialtyName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _chip(Icons.schedule_rounded, '${widget.doctor.consultStart}–${widget.doctor.consultEnd}'),
                        const SizedBox(width: 8),
                        _chip(Icons.payments_outlined, '₹${widget.doctor.consultationFee}'),
                        const SizedBox(width: 8),
                        _chip(Icons.star_rounded, widget.doctor.rating.toStringAsFixed(1), color: AppColors.star),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
