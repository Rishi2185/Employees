/// Doctor availability for a day: the window + days + slots already booked.
/// Slot generation itself stays client-side (see SlotGenerator); this only
/// tells us which slots to grey out.
class Availability {
  final String doctorId;
  final List<String> availableDays;
  final String consultStart;
  final String consultEnd;
  final bool availableToday;
  final String? dayKey;
  final List<String> bookedSlots;

  const Availability({
    required this.doctorId,
    required this.availableDays,
    required this.consultStart,
    required this.consultEnd,
    required this.availableToday,
    required this.dayKey,
    required this.bookedSlots,
  });

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
        doctorId: json['doctorId'] as String,
        availableDays:
            (json['availableDays'] as List?)?.map((e) => e as String).toList() ??
                const [],
        consultStart: (json['consultStart'] ?? '09:00') as String,
        consultEnd: (json['consultEnd'] ?? '17:00') as String,
        availableToday: (json['availableToday'] ?? false) as bool,
        dayKey: json['dayKey'] as String?,
        bookedSlots:
            (json['bookedSlots'] as List?)?.map((e) => e as String).toList() ??
                const [],
      );
}
