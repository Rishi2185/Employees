/// Helpers for the clinic-local `dayKey` (YYYY-MM-DD).
///
/// IMPORTANT: the authoritative dayKey is computed by the BACKEND in the clinic
/// timezone. The client must never derive a dayKey from `DateTime.now()` for
/// archive/EOD decisions — read it from appointment rows or `/stats/today`.
/// These helpers only compare/parse keys we already received from the server.
class DayKey {
  DayKey._();

  /// String comparison is valid ordering for YYYY-MM-DD.
  static bool isBefore(String a, String b) => a.compareTo(b) < 0;

  /// Parse a YYYY-MM-DD key into a local DateTime (midnight) for display only.
  static DateTime parse(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// The day before a given key (used to scan "past days" in the cloud).
  static String previous(String key) {
    final d = parse(key).subtract(const Duration(days: 1));
    return format(d);
  }

  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
