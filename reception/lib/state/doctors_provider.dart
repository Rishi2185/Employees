import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/availability.dart';
import '../models/doctor.dart';
import 'services.dart';

/// Loads the doctor roster (cloud Doctors store) for the walk-in booking flow
/// and the read-only doctor directory. Reception does not edit doctors — that's
/// the admin app — so this provider is read-only plus availability lookups.
class DoctorsProvider extends ChangeNotifier {
  final Services _services;
  DoctorsProvider(this._services);

  final List<Doctor> _doctors = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  bool _loaded = false;

  List<Doctor> get doctors => List.unmodifiable(_doctors);
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  bool get loaded => _loaded;

  Doctor? byId(String id) {
    for (final d in _doctors) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Doctors filtered locally by the current query (name / specialty).
  List<Doctor> get filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return doctors;
    return _doctors
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.specialtyName.toLowerCase().contains(q))
        .toList();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final Paged<Doctor> res =
          await _services.doctors.list(limit: 200, sort: 'relevance');
      _doctors
        ..clear()
        ..addAll(res.data);
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Booked slots + window for a doctor on a given clinic day (to grey out
  /// taken slots in the walk-in flow).
  Future<Availability?> availability(String doctorId, String dayKey) async {
    try {
      return await _services.doctors.availability(doctorId, dayKey);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
