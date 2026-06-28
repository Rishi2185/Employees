import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/doctor_input.dart';
import '../models/specialty.dart';
import '../state/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/avatar.dart';
import '../widgets/primary_button.dart';
import '../state/doctors_provider.dart';

/// Add or edit a doctor. On save, writes to the cloud Doctors store.
class DoctorEditScreen extends StatefulWidget {
  final Doctor? doctor;
  const DoctorEditScreen({super.key, this.doctor});

  bool get isEdit => doctor != null;

  @override
  State<DoctorEditScreen> createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends State<DoctorEditScreen> {
  late final DoctorInput _input = widget.doctor != null
      ? DoctorInput.fromDoctor(widget.doctor!)
      : DoctorInput();

  late final _name = TextEditingController(text: _input.name);
  late final _qualifications =
      TextEditingController(text: _input.qualifications);
  late final _experience =
      TextEditingController(text: _input.experienceYears.toString());
  late final _fee =
      TextEditingController(text: _input.consultationFee.toString());
  late final _about = TextEditingController(text: _input.about);
  late final _photoUrl = TextEditingController(text: _input.photoUrl);
  late final _hospital = TextEditingController(text: _input.hospitalName);
  late final _languages =
      TextEditingController(text: _input.languages.join(', '));

  String? _error;
  bool _uploading = false;

  final _picker = ImagePicker();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    for (final c in [
      _name,
      _qualifications,
      _experience,
      _fee,
      _about,
      _photoUrl,
      _hospital,
      _languages,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    _input
      ..name = _name.text
      ..qualifications = _qualifications.text
      ..experienceYears = int.tryParse(_experience.text.trim()) ?? 0
      ..consultationFee = int.tryParse(_fee.text.trim()) ?? 0
      ..about = _about.text
      ..photoUrl = _photoUrl.text
      ..hospitalName = _hospital.text
      ..languages = _languages.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

    final validation = _input.validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() => _error = null);

    final provider = context.read<DoctorsProvider>();
    final result = widget.isEdit
        ? await provider.update(widget.doctor!.id, _input)
        : await provider.create(_input);

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isEdit
              ? 'Saved. Patients now see the update.'
              : 'Doctor added.')));
      Navigator.of(context).pop(result);
    } else {
      setState(() => _error = provider.error ?? 'Save failed.');
    }
  }

  Future<void> _pickAndUpload() async {
    final services = context.read<Services>();
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final url = await services.imagekit.uploadDoctorPhoto(File(picked.path));
      if (!mounted) return;
      setState(() {
        _photoUrl.text = url;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorsProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text(
          widget.isEdit ? 'Edit Doctor' : 'Add Doctor',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Avatar profile preview
            Center(
              child: Column(
                children: [
                  Avatar(
                      name: _name.text.isEmpty ? 'New' : _name.text,
                      imageUrl: _photoUrl.text,
                      size: 80),
                  const SizedBox(height: 10),
                  if (widget.isEdit && !_input.active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Inactive — hidden from patients',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Professional details
            _sectionCard(
              title: 'Professional Details',
              icon: Icons.badge_outlined,
              children: [
                AppTextField(
                  label: 'Full name *',
                  controller: _name,
                  hint: 'e.g. Dr. Asha Rao',
                  prefixIcon: Icons.person_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _specialtyPicker(provider.specialties),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Experience (yrs)',
                        controller: _experience,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AppTextField(
                        label: 'Fee (₹)',
                        controller: _fee,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Qualifications',
                  controller: _qualifications,
                  hint: 'MBBS, MD',
                  prefixIcon: Icons.school_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Hospital Name',
                  controller: _hospital,
                  prefixIcon: Icons.local_hospital_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 2: Contact & Bio
            _sectionCard(
              title: 'Profile Info',
              icon: Icons.assignment_ind_outlined,
              children: [
                // ── Photo upload card ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor Photo',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _uploading ? null : _pickAndUpload,
                      child: AnimatedContainer(
                        duration: AppTheme.fast,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            if (_uploading)
                              const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            else if (_photoUrl.text.isNotEmpty)
                              Avatar(
                                  name: _name.text.isEmpty ? 'New' : _name.text,
                                  imageUrl: _photoUrl.text,
                                  size: 64)
                            else
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: const Icon(Icons.add_a_photo_rounded,
                                    color: AppColors.primary, size: 28),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              _photoUrl.text.isNotEmpty
                                  ? 'Tap to change photo'
                                  : 'Tap to upload photo',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Photo URL (or paste manually)',
                  controller: _photoUrl,
                  hint: 'https://…',
                  prefixIcon: Icons.link_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Languages (comma-separated)',
                  controller: _languages,
                  hint: 'English, Hindi',
                  prefixIcon: Icons.translate_rounded,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'About',
                  controller: _about,
                  hint: 'Short bio shown to patients',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 3: Availability & Hours
            _sectionCard(
              title: 'Availability & Hours',
              icon: Icons.schedule_rounded,
              children: [
                _consultHours(),
                const SizedBox(height: 20),
                _availableDays(),
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available today',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  subtitle: const Text('Patients can book slots for today'),
                  value: _input.availableToday,
                  onChanged: (v) => setState(() => _input.availableToday = v),
                ),
                if (widget.isEdit)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active roster visibility',
                        style:
                            TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: const Text('Visible in the patient booking catalog'),
                    value: _input.active,
                    onChanged: (v) => setState(() => _input.active = v),
                  ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: widget.isEdit ? 'Save changes' : 'Add doctor',
              icon: Icons.check_rounded,
              loading: provider.saving,
              onPressed: provider.saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _specialtyPicker(List<Specialty> specialties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specialty *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _input.specialtyId.isEmpty ? null : _input.specialtyId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary),
              hint: Text(specialties.isEmpty
                  ? 'Loading specialties…'
                  : 'Choose a specialty'),
              items: specialties
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final s = specialties.firstWhere((e) => e.id == id);
                setState(() {
                  _input.specialtyId = s.id;
                  _input.specialtyName = s.name;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _consultHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Consultation hours',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _timeField('From', _input.consultStart, (v) {
              setState(() => _input.consultStart = v);
            })),
            const SizedBox(width: 14),
            Expanded(child: _timeField('To', _input.consultEnd, (v) {
              setState(() => _input.consultEnd = v);
            })),
          ],
        ),
      ],
    );
  }

  Widget _timeField(String label, String value, ValueChanged<String> onPick) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        );
        final picked =
            await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          final hh = picked.hour.toString().padLeft(2, '0');
          final mm = picked.minute.toString().padLeft(2, '0');
          onPick('$hh:$mm');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text('$label  ',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _availableDays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available days',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdays.map((d) {
            final sel = _input.availableDays.contains(d);
            return ChoiceChip(
              label: Text(d),
              selected: sel,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.mint,
              labelStyle: TextStyle(
                color: sel ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (on) => setState(() {
                if (on) {
                  _input.availableDays.add(d);
                } else {
                  _input.availableDays.remove(d);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}
