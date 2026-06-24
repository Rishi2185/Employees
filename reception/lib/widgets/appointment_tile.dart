import 'package:flutter/material.dart';

import '../models/reception_appointment.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/status_ui.dart';
import 'avatar.dart';
import 'stat_card.dart';

/// A single appointment row used in the live list and the local archive.
/// Shows patient + doctor + slot, a status pill, and an optional trailing
/// actions area supplied by the caller.
class AppointmentTile extends StatelessWidget {
  final ReceptionAppointment appt;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDate;

  const AppointmentTile({
    super.key,
    required this.appt,
    this.onTap,
    this.trailing,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final patient = (appt.patientName?.trim().isNotEmpty ?? false)
        ? appt.patientName!
        : 'Walk-in / Unnamed';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Token chip or avatar
              if (appt.tokenNumber != null)
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('TKN',
                          style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600)),
                      Text('${appt.tokenNumber}',
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                )
              else
                Avatar(name: patient, size: 46),
              const SizedBox(width: 14),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (appt.checkedIn)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.how_to_reg_rounded,
                                size: 16, color: AppColors.success),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${appt.doctorName} · ${appt.specialtyName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          showDate
                              ? Fmt.dateWithSlot(appt.dateTime, appt.slotLabel)
                              : (appt.slotLabel.isEmpty
                                  ? Fmt.time(appt.dateTime)
                                  : appt.slotLabel),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (appt.patientPhone != null &&
                            appt.patientPhone!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.call_rounded,
                              size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            appt.patientPhone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Status + caller actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(
                    label: StatusUi.label(appt.status),
                    color: StatusUi.color(appt.status),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 6),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
