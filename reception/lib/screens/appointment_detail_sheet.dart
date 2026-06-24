import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reception_appointment.dart';
import '../models/slip.dart';
import '../services/slip_printer.dart';
import '../state/appointments_provider.dart';
import '../state/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/status_ui.dart';
import '../widgets/avatar.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_card.dart';

/// A bottom sheet showing one appointment's full details with reception
/// actions: check-in, change status, print slip, edit patient, cancel/remove.
class AppointmentDetailSheet extends StatefulWidget {
  final String appointmentId;
  final ReceptionAppointment initial;

  const AppointmentDetailSheet({
    super.key,
    required this.appointmentId,
    required this.initial,
  });

  @override
  State<AppointmentDetailSheet> createState() => _AppointmentDetailSheetState();
}

class _AppointmentDetailSheetState extends State<AppointmentDetailSheet> {
  late ReceptionAppointment _a = widget.initial;
  bool _busy = false;
  bool _printing = false;

  Future<void> _run(Future<ReceptionAppointment?> Function() action) async {
    setState(() => _busy = true);
    final updated = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (updated != null) _a = updated;
    });
  }

  Future<void> _printSlip() async {
    setState(() => _printing = true);
    final services = context.read<Services>();
    try {
      Slip slip;
      try {
        slip = await services.appointments.slip(_a.id);
      } catch (_) {
        // Offline / not found → build from the row we already have.
        slip = Slip.fromAppointment(_a, statusLabel: StatusUi.label(_a.status));
      }
      await SlipPrinter.print(slip,
          hospitalName: services.settings.hospitalName);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appts = context.read<AppointmentsProvider>();
    final patient = (_a.patientName?.trim().isNotEmpty ?? false)
        ? _a.patientName!
        : 'Walk-in / Unnamed';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  children: [
                    Row(
                      children: [
                        Avatar(name: patient, size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                _a.patientPhone?.isNotEmpty == true
                                    ? _a.patientPhone!
                                    : 'No phone on file',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: StatusUi.label(_a.status),
                          color: StatusUi.color(_a.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _infoCard(),
                    const SizedBox(height: 20),
                    if (_busy) const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 8),
                    _actions(appts),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softGreenTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('Doctor', _a.doctorName),
          _row('Specialty', _a.specialtyName),
          _row('Date', Fmt.longDate(_a.dateTime)),
          _row('Slot', _a.slotLabel.isEmpty ? Fmt.time(_a.dateTime) : _a.slotLabel),
          _row('Fee', Fmt.rupees(_a.fee)),
          _row('Payment', StatusUi.paymentLabel(_a.paymentMethod)),
          if (_a.tokenNumber != null) _row('Token', '#${_a.tokenNumber}'),
          if (_a.patientAge != null) _row('Age', '${_a.patientAge}'),
          if (_a.patientGender?.isNotEmpty == true)
            _row('Gender', _a.patientGender!),
          _row('Checked in', _a.checkedIn ? 'Yes' : 'No'),
          if (_a.source?.isNotEmpty == true) _row('Source', _a.source!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13.5)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
          ],
        ),
      );

  Widget _actions(AppointmentsProvider appts) {
    final canModify = !_a.isCancelled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printing ? null : _printSlip,
                icon: _printing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print slip'),
              ),
            ),
            const SizedBox(width: 12),
            if (canModify && !_a.checkedIn)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _run(() => appts.checkIn(_a.id)),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: const Text('Check in'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (canModify && !_a.isCompleted)
          PrimaryButton(
            label: 'Mark completed',
            icon: Icons.check_circle_rounded,
            onPressed:
                _busy ? null : () => _run(() => appts.markCompleted(_a.id)),
          ),
        if (canModify && _a.isCompleted)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(() => appts.markUpcoming(_a.id)),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Reopen (mark upcoming)'),
          ),
        const SizedBox(height: 12),
        if (canModify)
          TextButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await _run(() => appts.cancel(_a.id));
                  },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel appointment'),
          ),
      ],
    );
  }
}
