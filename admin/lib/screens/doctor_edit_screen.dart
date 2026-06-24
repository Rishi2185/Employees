import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/doctor_input.dart';
import '../models/specialty.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/avatar.dart';
import '../widgets/primary_button.dart';
import '../state/doctors_provider.dart';

/// Add or edit a doctor. On save, writes to the cloud Doctors store (→ patient
/// app). When [doctor] is null it's a create; otherwise an update.
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
    // Pull text fields into the input model.
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit doctor' : 'Add doctor'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Avatar(
                      name: _name.text.isEmpty ? 'New' : _name.text,
                      imageUrl: _photoUrl.text,
                      size: 76),
                  const SizedBox(height: 6),
                  if (widget.isEdit && !_input.active)
                    const Text('Inactive — hidden from patients',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Full name *',
              controller: _name,
              hint: 'e.g. Dr. Asha Rao',
              prefixIcon: Icons.person_outline_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _specialtyPicker(provider.specialties),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            AppTextField(
              label: 'Qualifications',
              controller: _qualifications,
              hint: 'MBBS, MD',
              prefixIcon: Icons.school_outlined,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Hospital',
              controller: _hospital,
              prefixIcon: Icons.local_hospital_outlined,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Photo URL',
              controller: _photoUrl,
              hint: 'https://…',
              prefixIcon: Icons.image_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Languages (comma-separated)',
              controller: _languages,
              hint: 'English, Hindi',
              prefixIcon: Icons.translate_rounded,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'About',
              controller: _about,
              hint: 'Short bio shown to patients',
            ),
            const SizedBox(height: 20),
            _consultHours(),
            const SizedBox(height: 20),
            _availableDays(),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available today',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              subtitle: const Text('Patients can book a slot today'),
              value: _input.availableToday,
              onChanged: (v) => setState(() => _input.availableToday = v),
            ),
            if (widget.isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                subtitle: const Text('Visible in the patient app'),
                value: _input.active,
                onChanged: (v) => setState(() => _input.active = v),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13)),
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

  Widget _specialtyPicker(List<Specialty> specialties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specialty *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _input.specialtyId.isEmpty ? null : _input.specialtyId,
              hint: Text(specialties.isEmpty
                  ? 'Loading specialties…'
                  : 'Choose a specialty'),
              items: specialties
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Text('$label  ',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textTertiary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdays.map((d) {
            final sel = _input.availableDays.contains(d);
            return FilterChip(
              label: Text(d),
              selected: sel,
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
