/// The admin live dashboard payload from `GET /stats/live` (admin only):
/// today's counts + a per-doctor breakdown + the count of future upcoming
/// appointments (bookings made for a later date are visible today).
class LiveStats {
  final String dayKey;
  final TodayCounts today;
  final List<DoctorLiveStat> perDoctor;
  final int futureUpcoming;

  const LiveStats({
    required this.dayKey,
    required this.today,
    required this.perDoctor,
    required this.futureUpcoming,
  });

  factory LiveStats.fromJson(Map<String, dynamic> j) => LiveStats(
        dayKey: (j['dayKey'] ?? '') as String,
        today: TodayCounts.fromJson(_asMap(j['today'])),
        perDoctor: ((j['perDoctor'] ?? const []) as List)
            .map((e) => DoctorLiveStat.fromJson(_asMap(e)))
            .toList(),
        futureUpcoming: (_asMap(j['future'])['upcoming'] as int?) ?? 0,
      );

  /// Coerce any (possibly loosely-typed or null) JSON value into a
  /// `Map<String, dynamic>` so empty/odd payloads never crash parsing.
  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  /// Total attended (completed) across all doctors today.
  int get attended => perDoctor.fold(0, (s, d) => s + d.completed);

  /// Total still pending across all doctors today.
  int get remaining => perDoctor.fold(0, (s, d) => s + d.pending);
}

class TodayCounts {
  final int todaysAppointments;
  final int completed;
  final int pending;
  final int cancelled;
  final int walkIns;

  const TodayCounts({
    this.todaysAppointments = 0,
    this.completed = 0,
    this.pending = 0,
    this.cancelled = 0,
    this.walkIns = 0,
  });

  factory TodayCounts.fromJson(Map<String, dynamic> j) => TodayCounts(
        todaysAppointments: (j['todaysAppointments'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
        walkIns: (j['walkIns'] ?? 0) as int,
      );
}

/// Per-doctor live counts for today — drives the load-distribution view.
class DoctorLiveStat {
  final String doctorId;
  final String doctorName;
  final int total;
  final int completed;
  final int cancelled;
  final int pending;

  const DoctorLiveStat({
    required this.doctorId,
    required this.doctorName,
    this.total = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pending = 0,
  });

  factory DoctorLiveStat.fromJson(Map<String, dynamic> j) => DoctorLiveStat(
        doctorId: (j['doctorId'] ?? '') as String,
        doctorName: (j['doctorName'] ?? '') as String,
        total: (j['total'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
      );

  /// Attended-vs-remaining progress for the day (0..1).
  double get progress => total == 0 ? 0 : completed / total;
}
