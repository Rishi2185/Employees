/// A per-day aggregate from the cloud Daily Summaries store (counts only).
class DailySummary {
  final String dayKey;
  final DateTime date;
  final SummaryCounts overall;
  final List<DoctorSummary> perDoctor;

  const DailySummary({
    required this.dayKey,
    required this.date,
    required this.overall,
    required this.perDoctor,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        dayKey: (json['dayKey'] ?? json['_id'] ?? '') as String,
        date: DateTime.tryParse((json['date'] ?? '') as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        overall: SummaryCounts.fromJson(_asMap(json['overall'])),
        perDoctor: ((json['perDoctor'] ?? const []) as List)
            .map((e) => DoctorSummary.fromJson(_asMap(e)))
            .toList(),
      );

  /// Coerce any (possibly null or loosely-typed) JSON value into a
  /// `Map<String, dynamic>` so empty/odd payloads never crash parsing.
  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
}

class SummaryCounts {
  final int total;
  final int completed;
  final int cancelled;
  final int pending;
  final int walkIns;
  final int revenue;

  const SummaryCounts({
    this.total = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pending = 0,
    this.walkIns = 0,
    this.revenue = 0,
  });

  factory SummaryCounts.fromJson(Map<String, dynamic> j) => SummaryCounts(
        total: (j['total'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
        walkIns: (j['walkIns'] ?? 0) as int,
        revenue: (j['revenue'] ?? 0) as int,
      );
}

class DoctorSummary {
  final String doctorId;
  final String doctorName;
  final int total;
  final int completed;
  final int cancelled;
  final int pending;

  const DoctorSummary({
    required this.doctorId,
    required this.doctorName,
    this.total = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pending = 0,
  });

  factory DoctorSummary.fromJson(Map<String, dynamic> j) => DoctorSummary(
        doctorId: (j['doctorId'] ?? '') as String,
        doctorName: (j['doctorName'] ?? '') as String,
        total: (j['total'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
      );
}
