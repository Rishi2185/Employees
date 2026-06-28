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
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 46,
                height: 5.5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                  children: [
                    // Header Area
                    Row(
                      children: [
                        Avatar(name: patient, size: 58),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _a.patientPhone?.isNotEmpty == true
                                    ? _a.patientPhone!
                                    : 'No phone number available',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: StatusUi.label(_a.status),
                          color: StatusUi.color(_a.status),
                          icon: _statusIcon(_a.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info Card layout
                    _infoCard(),
                    const SizedBox(height: 20),

                    // Process/Activity indicator
                    if (_busy)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            color: AppColors.primary,
                            backgroundColor: AppColors.mint,
                          ),
                        ),
                      ),

                    // Action Controls
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

  IconData _statusIcon(int status) {
    return switch (status) {
      0 => Icons.schedule_rounded,
      1 => Icons.check_circle_outline_rounded,
      2 => Icons.cancel_outlined,
      _ => Icons.info_outline_rounded,
    };
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Doctor', _a.doctorName, isBold: true),
          _row('Specialty', _a.specialtyName),
          _row('Date', Fmt.longDate(_a.dateTime)),
          _row('Slot', _a.slotLabel.isEmpty ? Fmt.time(_a.dateTime) : _a.slotLabel, isBold: true),
          _row('Consultation Fee', Fmt.rupees(_a.fee)),
          _row('Payment Mode', StatusUi.paymentLabel(_a.paymentMethod)),
          if (_a.tokenNumber != null) _row('Token Number', '#${_a.tokenNumber}', isAccent: true),
          if (_a.patientAge != null) _row('Age', '${_a.patientAge} years'),
          if (_a.patientGender?.isNotEmpty == true)
            _row('Gender', _a.patientGender!),
          _row('Checked In', _a.checkedIn ? 'Yes' : 'No', isAccent: _a.checkedIn),
          if (_a.source?.isNotEmpty == true) _row('Registration Source', _a.source!),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: (isBold || isAccent) ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
                color: isAccent
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(AppointmentsProvider appts) {
    final canModify = !_a.isCancelled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                onPressed: _printing ? null : _printSlip,
                icon: _printing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                label: const Text(
                  'Print slip',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            if (canModify && !_a.checkedIn)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.info, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                  onPressed:
                      _busy ? null : () => _run(() => appts.checkIn(_a.id)),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 18, color: AppColors.info),
                  label: const Text(
                    'Check in',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.info),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (canModify && !_a.isCompleted)
          PrimaryButton(
            label: 'Mark completed',
            icon: Icons.check_circle_rounded,
            onPressed:
                _busy ? null : () => _run(() => appts.markCompleted(_a.id)),
          ),
        if (canModify && _a.isCompleted)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
            onPressed: _busy ? null : () => _run(() => appts.markUpcoming(_a.id)),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text(
              'Reopen (mark upcoming)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
            label: const Text(
              'Cancel appointment',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
