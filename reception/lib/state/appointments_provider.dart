import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/reception_appointment.dart';
import 'services.dart';

/// Which slice of appointments the list is showing.
enum ApptScope { today, upcoming, byDate }

/// Drives the live Appointments screen: a filtered, paginated list backed by
/// the cloud Appointments store, plus the reception mutations (check-in, status
/// change, cancel, walk-in registration).
class AppointmentsProvider extends ChangeNotifier {
  final Services _services;
  AppointmentsProvider(this._services);

  // ---- query state ----
  ApptScope _scope = ApptScope.today;
  String? _dateKey; // for ApptScope.byDate
  String? _doctorId;
  int? _status; // 0/1/2 or null = all
  String _query = '';
  bool? _checkedIn;

  // ---- result state ----
  final List<ReceptionAppointment> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  static const _limit = 50;

  // ---- getters ----
  ApptScope get scope => _scope;
  String? get dateKey => _dateKey;
  String? get doctorId => _doctorId;
  int? get statusFilter => _status;
  String get query => _query;
  bool? get checkedIn => _checkedIn;

  List<ReceptionAppointment> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _items.length < _total;
  bool get isEmpty => !_loading && _items.isEmpty;

  // ---- filter mutations (each reloads) ----
  Future<void> setScope(ApptScope scope, {String? dateKey}) {
    _scope = scope;
    if (dateKey != null) _dateKey = dateKey;
    return refresh();
  }

  Future<void> setDoctor(String? doctorId) {
    _doctorId = doctorId;
    return refresh();
  }

  Future<void> setStatus(int? status) {
    _status = status;
    return refresh();
  }

  Future<void> setCheckedIn(bool? value) {
    _checkedIn = value;
    return refresh();
  }

  Future<void> setQuery(String q) {
    _query = q;
    return refresh();
  }

  void clearFilters() {
    _doctorId = null;
    _status = null;
    _checkedIn = null;
    _query = '';
    refresh();
  }

  /// (Re)load from page 1 using the current filters.
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    _page = 1;
    notifyListeners();
    try {
      final res = await _fetch(page: 1);
      _items
        ..clear()
        ..addAll(res.data);
      _total = res.total;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load the next page (infinite scroll).
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final res = await _fetch(page: _page + 1);
      _page += 1;
      _items.addAll(res.data);
      _total = res.total;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<Paged<ReceptionAppointment>> _fetch({required int page}) {
    String? date;
    String? from;
    switch (_scope) {
      case ApptScope.today:
        // null date + status filter → server defaults to today's window.
        // Use `from = today` is unnecessary; the list endpoint defaults to the
        // rolling window. We pass nothing special and rely on status/date.
        break;
      case ApptScope.upcoming:
        from = _todayHint; // best-effort; server clamps to its window
        break;
      case ApptScope.byDate:
        date = _dateKey;
        break;
    }
    return _services.appointments.list(
      date: date,
      from: from,
      doctorId: _doctorId,
      status: _status,
      q: _query.trim().isEmpty ? null : _query.trim(),
      checkedIn: _checkedIn,
      page: page,
      limit: _limit,
    );
  }

  /// A display-only hint for "upcoming" filtering. The authoritative day comes
  /// from the server; this just nudges the from-filter. Null is acceptable.
  String? get _todayHint => _dateKey;

  // ---- mutations ----

  /// Apply a patch and update the row in place. Returns the updated record.
  Future<ReceptionAppointment?> _patch(
      String id, Map<String, dynamic> changes) async {
    try {
      final updated = await _services.appointments.patch(id, changes);
      final i = _items.indexWhere((a) => a.id == id);
      if (i >= 0) {
        _items[i] = updated;
        notifyListeners();
      }
      return updated;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<ReceptionAppointment?> checkIn(String id, {bool value = true}) =>
      _patch(id, {'checkedIn': value});

  Future<ReceptionAppointment?> markCompleted(String id) =>
      _patch(id, {'status': 1});

  Future<ReceptionAppointment?> markUpcoming(String id) =>
      _patch(id, {'status': 0});

  Future<ReceptionAppointment?> setStatusOf(String id, int status) =>
      _patch(id, {'status': status});

  /// Backfill / correct patient identity on a record.
  Future<ReceptionAppointment?> updatePatient(
    String id, {
    String? patientName,
    String? patientPhone,
    int? patientAge,
    String? patientGender,
  }) =>
      _patch(id, {
        'patientName': ?patientName,
        'patientPhone': ?patientPhone,
        'patientAge': ?patientAge,
        'patientGender': ?patientGender,
      });

  /// Cancel (soft) — sets status to cancelled rather than deleting.
  Future<ReceptionAppointment?> cancel(String id) => _patch(id, {'status': 2});

  /// Hard remove (mistaken entry).
  Future<bool> remove(String id) async {
    try {
      await _services.appointments.deleteOne(id);
      _items.removeWhere((a) => a.id == id);
      _total = (_total - 1).clamp(0, 1 << 30);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Register a walk-in patient. On success the new record is inserted at the
  /// top of the current list (if it belongs to the active scope) and returned.
  Future<ReceptionAppointment?> registerWalkIn({
    required String doctorId,
    required DateTime dateTime,
    required String slotLabel,
    required String patientName,
    required String patientPhone,
    int? patientAge,
    String? patientGender,
    int? paymentMethod,
    int? fee,
    int? tokenNumber,
  }) async {
    try {
      final created = await _services.appointments.createWalkIn(
        doctorId: doctorId,
        dateTime: dateTime,
        slotLabel: slotLabel,
        patientName: patientName,
        patientPhone: patientPhone,
        patientAge: patientAge,
        patientGender: patientGender,
        paymentMethod: paymentMethod,
        fee: fee,
        tokenNumber: tokenNumber,
      );
      _items.insert(0, created);
      _total += 1;
      _error = null;
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
