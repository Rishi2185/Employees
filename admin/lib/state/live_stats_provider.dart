import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/live_stats.dart';
import 'services.dart';

/// Loads the live admin dashboard from `GET /stats/live`: today's counts, the
/// per-doctor breakdown, and the future-upcoming count.
class LiveStatsProvider extends ChangeNotifier {
  final Services _services;
  LiveStatsProvider(this._services);

  LiveStats? _stats;
  bool _loading = false;
  String? _error;
  DateTime? _loadedAt;

  LiveStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get loadedAt => _loadedAt;

  TodayCounts get today => _stats?.today ?? const TodayCounts();
  List<DoctorLiveStat> get perDoctor => _stats?.perDoctor ?? const [];
  int get futureUpcoming => _stats?.futureUpcoming ?? 0;
  String? get dayKey => _stats?.dayKey;

  /// Per-doctor list sorted by load (busiest first) for the distribution view.
  List<DoctorLiveStat> get byLoad {
    final list = [...perDoctor];
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _services.stats.live();
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
