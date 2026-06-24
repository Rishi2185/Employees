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
      subtitle: '${provider.doctors.length} on the roster',
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
            child: TextField(
              controller: _search,
              onChanged: provider.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search by name or specialty…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.loading && provider.doctors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const EmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No doctors',
                        message: 'No doctors match your search.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisExtent: 132,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) => FadeIn(
                          delay: Duration(milliseconds: (i % 8) * 40),
                          child: _DoctorCard(doctor: list[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: doctor.name, imageUrl: doctor.photoUrl, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(doctor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w700)),
                    ),
                    if (doctor.availableToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        ),
                        child: const Text('Today',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(doctor.specialtyName,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip(Icons.schedule_rounded,
                        '${doctor.consultStart}–${doctor.consultEnd}'),
                    const SizedBox(width: 8),
                    _chip(Icons.payments_outlined, '₹${doctor.consultationFee}'),
                    const SizedBox(width: 8),
                    _chip(Icons.star_rounded, doctor.rating.toStringAsFixed(1),
                        color: AppColors.star),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
