import 'package:intl/intl.dart';

/// Formatting helpers used across the app (shared with the patient app).
class Fmt {
  Fmt._();

  static String rupees(int amount) => '₹$amount';

  /// e.g. "Mon, 23 Jun"
  static String shortDate(DateTime d) => DateFormat('EEE, d MMM').format(d);

  /// e.g. "23 June 2026"
  static String longDate(DateTime d) => DateFormat('d MMMM yyyy').format(d);

  /// e.g. "Mon, 23 Jun · 10:30 AM"
  static String dateWithSlot(DateTime d, String slot) =>
      '${shortDate(d)} · $slot';

  /// "10:30 AM"
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  static String weekday(DateTime d) => DateFormat('EEE').format(d);

  static String dayNum(DateTime d) => DateFormat('d').format(d);

  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  /// "12.5k" style compact count.
  static String compact(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return '$n';
  }
}
