/// One day's numbers for a single doctor, from `GET /summaries?...&doctorId=`
/// (the server flattens its per-doctor sub-document to this shape). Drives the
/// per-doctor history chart ("how many did Dr. X attend last week/month").
class DoctorTrendPoint {
  final String dayKey;
  final DateTime date;
  final String doctorId;
  final int total;
  final int completed;
  final int cancelled;
  final int pending;

  const DoctorTrendPoint({
    required this.dayKey,
    required this.date,
    required this.doctorId,
    this.total = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pending = 0,
  });

  factory DoctorTrendPoint.fromJson(Map<String, dynamic> j) => DoctorTrendPoint(
        dayKey: (j['dayKey'] ?? '') as String,
        date: DateTime.tryParse((j['date'] ?? '') as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        doctorId: (j['doctorId'] ?? '') as String,
        total: (j['total'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
      );
}
