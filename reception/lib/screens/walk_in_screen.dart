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
      subtitle: 'Book a patient who arrived at the desk',
      child: doctors.loading && doctors.doctors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: doctor + slot
                  Expanded(
                    flex: 5,
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
                  const SizedBox(width: 24),
                  // Right: patient details
                  Expanded(flex: 4, child: _patientForm()),
                ],
              ),
            ),
    );
  }

  Widget _patientForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Full name',
            controller: _name,
            hint: 'e.g. Anita Sharma',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Phone',
            controller: _phone,
            hint: '10-digit mobile',
            prefixIcon: Icons.call_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: AppTextField(
                  label: 'Age',
                  controller: _age,
                  hint: 'yrs',
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
          const SizedBox(height: 16),
          _paymentSelect(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Register & continue',
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
        const Text('Gender',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Female', 'Male', 'Other'].map((g) {
            final sel = g == _gender;
            return ChoiceChip(
              label: Text(g),
              selected: sel,
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
        const Text('Payment',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: StatusUi.paymentLabels.entries.map((e) {
            final sel = e.key == _payment;
            return ChoiceChip(
              label: Text(e.value),
              selected: sel,
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
        title: 'No doctors',
        message: 'The roster is empty or could not be loaded.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select doctor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: doctors.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = doctors[i];
              final sel = d.id == selected?.id;
              return ListTile(
                onTap: () => onDoctor(d),
                leading: Avatar(name: d.name, imageUrl: d.photoUrl, size: 40),
                title: Text(d.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${d.specialtyName} · ₹${d.consultationFee}'),
                trailing: sel
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary),
                selected: sel,
                selectedTileColor: AppColors.mint,
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Text(
          selected == null ? 'Slots' : 'Available slots for ${selected!.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (selected == null)
          const Text('Pick a doctor to see open slots.',
              style: TextStyle(color: AppColors.textSecondary))
        else
          _slotGrid(context),
      ],
    );
  }

  Widget _slotGrid(BuildContext context) {
    final date = DayKey.parse(dayKey);
    final all = SlotGenerator.allFor(selected!.id, date);
    if (all.isEmpty) {
      return const Text('No slots configured for this day.',
          style: TextStyle(color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: all.map((s) {
        final booked = bookedSlots.contains(s);
        final sel = s == slot;
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: booked ? null : () => onSlot(s),
          child: AnimatedContainer(
            duration: AppTheme.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: booked
                  ? AppColors.scaffold
                  : sel
                      ? AppColors.primary
                      : AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: sel ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              s,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: booked ? TextDecoration.lineThrough : null,
                color: booked
                    ? AppColors.textTertiary
                    : sel
                        ? Colors.white
                        : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
