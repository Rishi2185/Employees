import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/reception_appointment.dart';
import '../models/slip.dart';
import '../services/slip_printer.dart';
import '../state/appointments_provider.dart';
import '../state/dashboard_provider.dart';
import '../state/doctors_provider.dart';
import '../state/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/day_key.dart';
import '../utils/slot_generator.dart';
import '../utils/status_ui.dart';
import '../widgets/app_text_field.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/fade_in.dart';

/// Register a walk-in patient who arrived without booking in the app. Picks a
/// doctor + an open slot for the clinic day, captures patient identity, books
/// it on the cloud, and offers an immediate slip print.
class WalkInScreen extends StatefulWidget {
  const WalkInScreen({super.key});

  @override
  State<WalkInScreen> createState() => _WalkInScreenState();
}

class _WalkInScreenState extends State<WalkInScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();

  Doctor? _doctor;
  String? _slot;
  String _gender = 'Female';
  int _payment = 1; // UPI default
  List<String> _bookedSlots = const [];
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorsProvider>().load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _age.dispose();
    super.dispose();
  }

  /// The clinic day key, taken from the dashboard's server-reported value, or
  /// best-effort from the local date as a fallback for slot display.
  String get _dayKey =>
      context.read<DashboardProvider>().dayKey ?? DayKey.format(DateTime.now());

  Future<void> _selectDoctor(Doctor d) async {
    setState(() {
      _doctor = d;
      _slot = null;
      _bookedSlots = const [];
    });
    final avail =
        await context.read<DoctorsProvider>().availability(d.id, _dayKey);
    if (mounted && avail != null) {
      setState(() => _bookedSlots = avail.bookedSlots);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final doctor = _doctor;
    if (doctor == null) {
      setState(() => _error = 'Select a doctor.');
      return;
    }
    if (_slot == null) {
      setState(() => _error = 'Pick an available slot.');
      return;
    }
    if (_name.text.trim().isEmpty || _phone.text.trim().length < 7) {
      setState(() => _error = 'Enter the patient name and a valid phone.');
      return;
    }

    setState(() => _submitting = true);
    final appts = context.read<AppointmentsProvider>();
    final dateTime = SlotGenerator.toDateTime(DayKey.parse(_dayKey), _slot!);

    final created = await appts.registerWalkIn(
      doctorId: doctor.id,
      dateTime: dateTime,
      slotLabel: _slot!,
      patientName: _name.text.trim(),
      patientPhone: _phone.text.trim(),
      patientAge: int.tryParse(_age.text.trim()),
      patientGender: _gender,
      paymentMethod: _payment,
      fee: doctor.consultationFee,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (created == null) {
      setState(() => _error = appts.error ?? 'Could not register the walk-in.');
      return;
    }
    await _onRegistered(created);
  }

  Future<void> _onRegistered(ReceptionAppointment created) async {
    // Refresh the dashboard tile counts in the background.
    context.read<DashboardProvider>().load();

    final printNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Walk-in registered'),
        content: Text(
          'Token #${created.tokenNumber ?? '-'} booked for '
          '${created.patientName}. Print the slip now?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now')),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print slip'),
          ),
        ],
      ),
    );

    if (printNow == true && mounted) {
      final services = context.read<Services>();
      Slip slip;
      try {
        slip = await services.appointments.slip(created.id);
      } catch (_) {
        slip = Slip.fromAppointment(created,
            statusLabel: StatusUi.label(created.status));
      }
      await SlipPrinter.print(slip,
          hospitalName: services.settings.hospitalName);
    }

    if (mounted) _resetForm();
  }

  void _resetForm() {
    setState(() {
      _name.clear();
      _phone.clear();
      _age.clear();
      _slot = null;
      _doctor = null;
      _bookedSlots = const [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctors = context.watch<DoctorsProvider>();

    return ScreenScaffold(
      title: 'Register walk-in',
      subtitle: 'Book a patient who arrived at the front desk',
      child: doctors.loading && doctors.doctors.isEmpty
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: doctor + slot selection panel
                  Expanded(
                    flex: 5,
                    child: FadeIn(
                      delay: const Duration(milliseconds: 50),
                      scaleFrom: 0.98,
                      child: _DoctorSlotPanel(
                        doctors: doctors.doctors,
                        selected: _doctor,
                        bookedSlots: _bookedSlots,
                        slot: _slot,
                        dayKey: _dayKey,
                        onDoctor: _selectDoctor,
                        onSlot: (s) => setState(() => _slot = s),
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  // Right: patient details registration form
                  Expanded(
                    flex: 4,
                    child: FadeIn(
                      delay: const Duration(milliseconds: 150),
                      scaleFrom: 0.98,
                      child: _patientForm(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _patientForm() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Patient registration',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Full name *',
            controller: _name,
            hint: 'e.g. Anita Sharma',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone number *',
            controller: _phone,
            hint: '10-digit mobile number',
            prefixIcon: Icons.call_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: AppTextField(
                  label: 'Age',
                  controller: _age,
                  hint: 'Yrs',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _genderSelect()),
            ],
          ),
          const SizedBox(height: 18),
          _paymentSelect(),
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
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Register & book now',
            icon: Icons.check_rounded,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _genderSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Female', 'Male', 'Other'].map((g) {
            final sel = g == _gender;
            return ChoiceChip(
              label: Text(g),
              selected: sel,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.mint,
              labelStyle: TextStyle(
                color: sel ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => setState(() => _gender = g),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _paymentSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Mode',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: StatusUi.paymentLabels.entries.map((e) {
            final sel = e.key == _payment;
            return ChoiceChip(
              label: Text(e.value),
              selected: sel,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.mint,
              labelStyle: TextStyle(
                color: sel ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => setState(() => _payment = e.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DoctorSlotPanel extends StatelessWidget {
  final List<Doctor> doctors;
  final Doctor? selected;
  final List<String> bookedSlots;
  final String? slot;
  final String dayKey;
  final ValueChanged<Doctor> onDoctor;
  final ValueChanged<String> onSlot;

  const _DoctorSlotPanel({
    required this.doctors,
    required this.selected,
    required this.bookedSlots,
    required this.slot,
    required this.dayKey,
    required this.onDoctor,
    required this.onSlot,
  });

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'No doctors rostered',
        message: 'The roster is empty or could not be loaded.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select doctor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          constraints: const BoxConstraints(maxHeight: 260),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: doctors.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = doctors[i];
                final sel = d.id == selected?.id;
                return ListTile(
                  onTap: () => onDoctor(d),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Avatar(name: d.name, imageUrl: d.photoUrl, size: 42),
                  title: Text(
                    d.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${d.specialtyName} · ₹${d.consultationFee}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  trailing: sel
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                      : const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  selected: sel,
                  selectedTileColor: AppColors.mint.withValues(alpha: 0.5),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          selected == null ? 'Time slots' : 'Available slots for ${selected!.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (selected == null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Select a doctor from the list to display slot options.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          _slotGrid(context),
      ],
    );
  }

  Widget _slotGrid(BuildContext context) {
    final date = DayKey.parse(dayKey);
    final all = SlotGenerator.allFor(selected!.id, date);
    if (all.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No slots configured for this doctor on this day.',
          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: all.map((s) {
        final booked = bookedSlots.contains(s);
        final sel = s == slot;
        return _SlotChip(
          label: s,
          booked: booked,
          selected: sel,
          onTap: () => onSlot(s),
        );
      }).toList(),
    );
  }
}

class _SlotChip extends StatefulWidget {
  final String label;
  final bool booked;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.booked,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SlotChip> createState() => _SlotChipState();
}

class _SlotChipState extends State<_SlotChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.booked ? null : setState(() => _hovered = true),
      onExit: (_) => widget.booked ? null : setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: widget.booked ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: widget.booked
                ? AppColors.scaffold
                : widget.selected
                    ? AppColors.primary
                    : _hovered
                        ? AppColors.mint.withValues(alpha: 0.4)
                        : AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: widget.selected ? AppColors.primary : AppColors.border,
              width: widget.selected ? 1.5 : 1.0,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : _hovered
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w700,
              decoration: widget.booked ? TextDecoration.lineThrough : null,
              color: widget.booked
                  ? AppColors.textTertiary
                  : widget.selected
                      ? Colors.white
                      : _hovered
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
