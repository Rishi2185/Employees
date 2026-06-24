import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Maps the backend's integer appointment status (0/1/2) to a label + color.
/// Guarded: an unexpected value renders as "Unknown" rather than crashing
/// (unlike the patient app's `AppointmentStatus.values[index]`).
class StatusUi {
  StatusUi._();

  static const int upcoming = 0;
  static const int completed = 1;
  static const int cancelled = 2;

  static String label(int status) {
    switch (status) {
      case upcoming:
        return 'Upcoming';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  static Color color(int status) {
    switch (status) {
      case upcoming:
        return AppColors.info;
      case completed:
        return AppColors.success;
      case cancelled:
        return AppColors.danger;
      default:
        return AppColors.textTertiary;
    }
  }

  static const Map<int, String> paymentLabels = {
    0: 'Card',
    1: 'UPI',
    2: 'Wallet',
  };

  static String paymentLabel(int method) => paymentLabels[method] ?? 'Other';
}
