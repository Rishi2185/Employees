import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/doctor.dart';
import '../models/doctor_input.dart';
import '../models/specialty.dart';
import 'services.dart';

/// Manages the doctor roster for the admin app: list (optionally including
/// soft-deleted doctors), client-side search, and create / update / deactivate /
/// reactivate writes that flow to the cloud and the patient app.
class DoctorsProvider extends ChangeNotifier {
  final Services _services;
  DoctorsProvider(this._services);

  final List<Doctor> _doctors = [];
  List<Specialty> _specialties = const [];
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String _query = '';
  bool _includeInactive = true;
  bool _loaded = false;

  List<Doctor> get all => List.unmodifiable(_doctors);
  List<Specialty> get specialties => List.unmodifiable(_specialties);
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String get query => _query;
  bool get includeInactive => _includeInactive;
  bool get loaded => _loaded;

  int get activeCount => _doctors.where((d) => d.active).length;
  int get inactiveCount => _doctors.where((d) => !d.active).length;

  Doctor? byId(String id) {
    for (final d in _doctors) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Doctors filtered locally by the current search query.
  List<Doctor> get filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return _doctors
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.specialtyName.toLowerCase().contains(q) ||
            d.qualifications.toLowerCase().contains(q))
        .toList();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  Future<void> toggleIncludeInactive(bool value) async {
    _includeInactive = value;
    await load(force: true);
  }

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _services.doctors
            .list(includeInactive: _includeInactive, limit: 200, sort: 'relevance'),
        if (_specialties.isEmpty) _services.meta.specialties(),
      ]);
      final page = results[0] as Paged<Doctor>;
      _doctors
        ..clear()
        ..addAll(page.data);
      if (results.length > 1) _specialties = results[1] as List<Specialty>;
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create a doctor. Returns the created record, or null on failure.
  Future<Doctor?> create(DoctorInput input) async {
    return _write(() => _services.doctors.create(input), insert: true);
  }

  /// Update a doctor. Returns the updated record, or null on failure.
  Future<Doctor?> update(String id, DoctorInput input) async {
    return _write(() => _services.doctors.update(id, input));
  }

  /// Soft-delete (deactivate). Updates the row's active flag in place.
  Future<bool> deactivate(String id) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _services.doctors.deactivate(id);
      final i = _doctors.indexWhere((d) => d.id == id);
      if (i >= 0) _doctors[i] = _doctors[i].copyWith(active: false);
      // If we're hiding inactive doctors, drop it from the list.
      if (!_includeInactive) _doctors.removeWhere((d) => d.id == id);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<Doctor?> reactivate(String id) async {
    return _write(() => _services.doctors.reactivate(id));
  }

  Future<Doctor?> _write(Future<Doctor> Function() action,
      {bool insert = false}) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final doc = await action();
      final i = _doctors.indexWhere((d) => d.id == doc.id);
      if (i >= 0) {
        _doctors[i] = doc;
      } else if (insert) {
        _doctors.insert(0, doc);
      }
      return doc;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
