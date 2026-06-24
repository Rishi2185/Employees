/// Generates deterministic time-slots for a doctor on a given date — the same
/// algorithm the patient app uses, refactored to take a doctorId string instead
/// of the (differently-shaped) Doctor model.
class SlotGenerator {
  SlotGenerator._();

  static const List<String> _morning = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
  ];

  static const List<String> _afternoon = [
    '12:00 PM',
    '12:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
  ];

  static const List<String> _evening = [
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
  ];

  static List<String> morning(String doctorId, DateTime date) =>
      _filter(_morning, doctorId, date, 0);
  static List<String> afternoon(String doctorId, DateTime date) =>
      _filter(_afternoon, doctorId, date, 1);
  static List<String> evening(String doctorId, DateTime date) =>
      _filter(_evening, doctorId, date, 2);

  /// All slots for a day, in order.
  static List<String> allFor(String doctorId, DateTime date) => [
        ...morning(doctorId, date),
        ...afternoon(doctorId, date),
        ...evening(doctorId, date),
      ];

  /// Deterministically removes a few slots so availability varies by day,
  /// using the doctor id + date as a seed (no randomness needed).
  static List<String> _filter(
      List<String> slots, String doctorId, DateTime date, int band) {
    final seed = doctorId.hashCode ^ (date.day * 31) ^ (date.month * 131) ^ band;
    final result = <String>[];
    for (var i = 0; i < slots.length; i++) {
      if ((seed + i * 7) % 3 != 0) {
        result.add(slots[i]);
      }
    }
    return result;
  }

  /// Parse a slot label like "10:30 AM" into hour/minute (24h).
  static (int, int) parse(String slot) {
    final parts = slot.split(' ');
    final hm = parts[0].split(':');
    var hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);
    final pm = parts[1] == 'PM';
    if (pm && hour != 12) hour += 12;
    if (!pm && hour == 12) hour = 0;
    return (hour, minute);
  }

  static DateTime toDateTime(DateTime date, String slot) {
    final (h, m) = parse(slot);
    return DateTime(date.year, date.month, date.day, h, m);
  }
}
