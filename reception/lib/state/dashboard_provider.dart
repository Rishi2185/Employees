import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/stats.dart';
import 'services.dart';

/// Feeds the dashboard tiles + doctor-wise breakdown.
///
/// Live numbers come from the cloud `/stats` endpoints; the all-time "Total
/// Patients" tile prefers the precise local-archive count (visits this terminal
/// has permanently recorded) and falls back to the server's derived figure.
class DashboardProvider extends ChangeNotifier {
  final Services _services;
  DashboardProvider(this._services);

  TodayStats? _today;
  Overview? _overview;
  List<DoctorStat> _doctorStats = const [];
  int? _localArchivedVisits;

  bool _loading = false;
  String? _error;
  DateTime? _loadedAt;

  TodayStats? get today => _today;
  Overview? get overview => _overview;
  List<DoctorStat> get doctorStats => List.unmodifiable(_doctorStats);
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get loadedAt => _loadedAt;

  /// The clinic day key, as reported by the server (authoritative).
  String? get dayKey => _today?.dayKey ?? _overview?.dayKey;

  int get todaysAppointments => _today?.todaysAppointments ?? 0;
  int get completed => _today?.completed ?? 0;
  int get pending => _today?.pending ?? 0;
  int get cancelled => _today?.cancelled ?? 0;
  int get walkIns => _today?.walkIns ?? 0;

  /// "Total Patients" — local archive total (preferred) + today's live count,
  /// or the server's all-time figure when the archive is empty.
  int get totalPatients {
    final local = _localArchivedVisits;
    if (local != null && local > 0) return local + todaysAppointments;
    return _overview?.totalPatientsAllTime ?? 0;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Fire the independent reads together.
      final results = await Future.wait([
        _services.stats.today(),
        _services.stats.overview(),
        _services.stats.doctors(),
        _services.archive.totalArchivedVisits(),
      ]);
      _today = results[0] as TodayStats;
      _overview = results[1] as Overview;
      _doctorStats = results[2] as List<DoctorStat>;
      _localArchivedVisits = results[3] as int;
      _loadedAt = DateTime.now();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
