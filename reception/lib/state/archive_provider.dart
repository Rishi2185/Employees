import 'package:flutter/foundation.dart';

import '../db/archive_dao.dart';
import '../models/reception_appointment.dart';
import 'services.dart';

/// Drives the local Archive screen: fast, indexed search over the durable
/// SQLite record of every past appointment. Works fully offline.
class ArchiveProvider extends ChangeNotifier {
  final Services _services;
  ArchiveProvider(this._services);

  final List<ReceptionAppointment> _rows = [];
  List<String> _days = const [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  // query
  String _query = '';
  String? _dayKey;
  String? _doctorId;
  int? _status;

  int _page = 1;
  int _total = 0;
  static const _limit = 50;

  List<ReceptionAppointment> get rows => List.unmodifiable(_rows);
  List<String> get days => List.unmodifiable(_days);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  String get query => _query;
  String? get dayKey => _dayKey;
  int? get status => _status;
  int get total => _total;
  bool get hasMore => _rows.length < _total;
  bool get isEmpty => !_loading && _rows.isEmpty;

  ArchiveDao get _dao => _services.archive;

  Future<void> init() async {
    _days = await _dao.archivedDays();
    await search();
  }

  void setQuery(String q) {
    _query = q;
    search();
  }

  void setDay(String? dayKey) {
    _dayKey = dayKey;
    search();
  }

  void setDoctor(String? doctorId) {
    _doctorId = doctorId;
    search();
  }

  void setStatus(int? status) {
    _status = status;
    search();
  }

  void clearFilters() {
    _query = '';
    _dayKey = null;
    _doctorId = null;
    _status = null;
    search();
  }

  Future<void> search() async {
    _loading = true;
    _error = null;
    _page = 1;
    notifyListeners();
    try {
      final res = await _dao.search(
        q: _query,
        dayKey: _dayKey,
        doctorId: _doctorId,
        status: _status,
        page: 1,
        limit: _limit,
      );
      _rows
        ..clear()
        ..addAll(res.rows);
      _total = res.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || _loading || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final res = await _dao.search(
        q: _query,
        dayKey: _dayKey,
        doctorId: _doctorId,
        status: _status,
        page: _page + 1,
        limit: _limit,
      );
      _page += 1;
      _rows.addAll(res.rows);
      _total = res.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Counts for a given archived day (drives the per-day summary header).
  Future<ArchiveDayCounts> countsForDay(String dayKey) =>
      _dao.countsForDay(dayKey);
}
