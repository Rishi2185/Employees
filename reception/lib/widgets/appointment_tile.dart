import 'package:flutter/material.dart';

import '../models/reception_appointment.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/status_ui.dart';
import 'avatar.dart';
import 'stat_card.dart';

/// A single appointment row used in the live list and the local archive.
/// Features smooth hover scale, glow transitions, and a premium token chip.
class AppointmentTile extends StatefulWidget {
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
  State<AppointmentTile> createState() => _AppointmentTileState();
}

class _AppointmentTileState extends State<AppointmentTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final patient = (widget.appt.patientName?.trim().isNotEmpty ?? false)
        ? widget.appt.patientName!
        : 'Walk-in / Unnamed';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.01 : 1.0,
        duration: AppTheme.fast,
        curve: AppTheme.curve,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: AppTheme.curve,
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Token chip or avatar
                    if (widget.appt.tokenNumber != null)
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.mint,
                              AppColors.mintDark.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('TOKEN',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w800)),
                            Text('${widget.appt.tokenNumber}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark)),
                          ],
                        ),
                      )
                    else
                      Avatar(name: patient, size: 48),
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
                              if (widget.appt.checkedIn)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Tooltip(
                                    message: 'Checked In',
                                    child: Icon(Icons.how_to_reg_rounded,
                                        size: 17, color: AppColors.success),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.appt.doctorName} · ${widget.appt.specialtyName}',
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
                                widget.showDate
                                    ? Fmt.dateWithSlot(widget.appt.dateTime, widget.appt.slotLabel)
                                    : (widget.appt.slotLabel.isEmpty
                                        ? Fmt.time(widget.appt.dateTime)
                                        : widget.appt.slotLabel),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.appt.patientPhone != null &&
                                  widget.appt.patientPhone!.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.call_rounded,
                                    size: 12, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  widget.appt.patientPhone!,
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
                          label: StatusUi.label(widget.appt.status),
                          color: StatusUi.color(widget.appt.status),
                          icon: _statusIcon(widget.appt.status),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(height: 6),
                          widget.trailing!,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(int status) {
    return switch (status) {
      0 => Icons.schedule_rounded, // upcoming
      1 => Icons.check_circle_outline_rounded, // completed
      2 => Icons.cancel_outlined, // cancelled
      _ => Icons.info_outline_rounded,
    };
  }
}
