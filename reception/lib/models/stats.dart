// Dashboard DTOs from the /stats endpoints.

class TodayStats {
  final String dayKey;
  final int todaysAppointments;
  final int completed;
  final int pending;
  final int cancelled;
  final int walkIns;

  const TodayStats({
    required this.dayKey,
    required this.todaysAppointments,
    required this.completed,
    required this.pending,
    required this.cancelled,
    required this.walkIns,
  });

  factory TodayStats.fromJson(Map<String, dynamic> j) => TodayStats(
        dayKey: (j['dayKey'] ?? '') as String,
        todaysAppointments: (j['todaysAppointments'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
        walkIns: (j['walkIns'] ?? 0) as int,
      );
}

class Overview {
  final String dayKey;
  final int totalPatientsAllTime; // visits, not unique patients
  final int historicalVisits;
  final int todaysAppointments;
  final int completed;
  final int pending;
  final int cancelled;

  const Overview({
    required this.dayKey,
    required this.totalPatientsAllTime,
    required this.historicalVisits,
    required this.todaysAppointments,
    required this.completed,
    required this.pending,
    required this.cancelled,
  });

  factory Overview.fromJson(Map<String, dynamic> j) => Overview(
        dayKey: (j['dayKey'] ?? '') as String,
        totalPatientsAllTime: (j['totalPatientsAllTime'] ?? 0) as int,
        historicalVisits: (j['historicalVisits'] ?? 0) as int,
        todaysAppointments: (j['todaysAppointments'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
      );
}

class DoctorStat {
  final String doctorId;
  final String doctorName;
  final int total;
  final int completed;
  final int pending;
  final int cancelled;

  const DoctorStat({
    required this.doctorId,
    required this.doctorName,
    required this.total,
    required this.completed,
    required this.pending,
    required this.cancelled,
  });

  factory DoctorStat.fromJson(Map<String, dynamic> j) => DoctorStat(
        doctorId: (j['doctorId'] ?? '') as String,
        doctorName: (j['doctorName'] ?? '') as String,
        total: (j['total'] ?? 0) as int,
        completed: (j['completed'] ?? 0) as int,
        pending: (j['pending'] ?? 0) as int,
        cancelled: (j['cancelled'] ?? 0) as int,
      );
}
