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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add doctor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _search,
              onChanged: provider.setQuery,
              decoration: const InputDecoration(
                hintText: 'Search doctors…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${provider.activeCount} active · ${provider.inactiveCount} inactive',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
                const Spacer(),
                const Text('Show inactive',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
                Switch(
                  value: provider.includeInactive,
                  onChanged: (v) => provider.toggleIncludeInactive(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading && provider.all.isEmpty
                ? const Center(child: CircularProgressIndicator())
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
                            title: 'No doctors',
                            message: 'Add your first doctor with the button below.',
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.load(force: true),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 96),
                              itemCount: list.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) => FadeIn(
                                delay: Duration(milliseconds: (i % 10) * 35),
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

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  const _DoctorCard({required this.doctor, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DoctorsProvider>();
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: doctor.active ? 1 : 0.5,
                child: Avatar(
                    name: doctor.name, imageUrl: doctor.photoUrl, size: 50),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(doctor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        if (!doctor.active)
                          _badge('Inactive', AppColors.textTertiary)
                        else if (doctor.availableToday)
                          _badge('In today', AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${doctor.specialtyName} · ₹${doctor.consultationFee}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      '${doctor.experienceYears} yrs'
                      '${doctor.qualifications.isNotEmpty ? ' · ${doctor.qualifications}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              _menu(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _menu(BuildContext context, DoctorsProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      onSelected: (v) async {
        if (v == 'edit') {
          onEdit();
        } else if (v == 'deactivate') {
          final ok = await _confirmDeactivate(context);
          if (ok == true) {
            final done = await provider.deactivate(doctor.id);
            if (context.mounted) {
              _snack(context,
                  done ? '${doctor.name} deactivated.' : provider.error ?? 'Failed.');
            }
          }
        } else if (v == 'reactivate') {
          final res = await provider.reactivate(doctor.id);
          if (context.mounted) {
            _snack(context,
                res != null ? '${doctor.name} reactivated.' : provider.error ?? 'Failed.');
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (doctor.active)
          const PopupMenuItem(
              value: 'deactivate', child: Text('Deactivate'))
        else
          const PopupMenuItem(
              value: 'reactivate', child: Text('Reactivate')),
      ],
    );
  }

  Future<bool?> _confirmDeactivate(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Deactivate ${doctor.name}?'),
          content: const Text(
              'The doctor will be hidden from the patient app. Past appointments '
              'keep their name. You can reactivate any time.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
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
