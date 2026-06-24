import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/daily_summary.dart';
import '../models/doctor_trend.dart';
import '../utils/day_key.dart';
import 'services.dart';

/// Selectable look-back windows for the trends charts.
enum TrendRange {
  week(7, '7 days'),
  month(30, '30 days'),
  quarter(90, '90 days');

  final int days;
  final String label;
  const TrendRange(this.days, this.label);
}

/// A single (day, value) point for charting.
class TrendPoint {
  final String dayKey;
  final DateTime date;
  final int total;
  final int completed;
  final int cancelled;
  const TrendPoint({
    required this.dayKey,
    required this.date,
    required this.total,
    required this.completed,
    required this.cancelled,
  });
}

/// Loads historical trends from the cloud Daily Summaries store. Supports an
/// overall view (all doctors) or a single-doctor view, over a selectable range.
///
/// The date window is computed from the local clock — acceptable here because
/// it only bounds a multi-day query, not an authoritative clinic-day decision.
class TrendsProvider extends ChangeNotifier {
  final Services _services;
  TrendsProvider(this._services);

  TrendRange _range = TrendRange.month;
  String? _doctorId; // null = overall
  String? _doctorName;

  List<TrendPoint> _points = const [];
  bool _loading = false;
  String? _error;

  TrendRange get range => _range;
  String? get doctorId => _doctorId;
  String? get doctorName => _doctorName;
  List<TrendPoint> get points => List.unmodifiable(_points);
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => !_loading && _points.isEmpty;

  // ---- aggregates over the loaded window ----
  int get totalAppointments => _points.fold(0, (s, p) => s + p.total);
  int get totalCompleted => _points.fold(0, (s, p) => s + p.completed);
  int get totalCancelled => _points.fold(0, (s, p) => s + p.cancelled);
  int get peakDay =>
      _points.isEmpty ? 0 : _points.map((p) => p.total).reduce((a, b) => a > b ? a : b);
  double get avgPerDay =>
      _points.isEmpty ? 0 : totalAppointments / _points.length;

  void setRange(TrendRange r) {
    _range = r;
    load();
  }

  /// Switch between the overall view (doctorId == null) and a doctor view.
  void setDoctor(String? doctorId, {String? doctorName}) {
    _doctorId = doctorId;
    _doctorName = doctorName;
    load();
  }

  ({String from, String to}) _window() {
    final now = DateTime.now();
    final to = DayKey.format(now);
    final from = DayKey.format(now.subtract(Duration(days: _range.days - 1)));
    return (from: from, to: to);
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final w = _window();
    try {
      if (_doctorId == null) {
        final summaries =
            await _services.summaries.overall(from: w.from, to: w.to);
        _points = summaries.map(_fromSummary).toList();
      } else {
        final trend = await _services.summaries
            .forDoctor(_doctorId!, from: w.from, to: w.to);
        _points = trend.map(_fromDoctorPoint).toList();
      }
    } on ApiException catch (e) {
      _error = e.message;
      _points = const [];
    } catch (e) {
      _error = e.toString();
      _points = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  TrendPoint _fromSummary(DailySummary s) => TrendPoint(
        dayKey: s.dayKey,
        date: s.date,
        total: s.overall.total,
        completed: s.overall.completed,
        cancelled: s.overall.cancelled,
      );

  TrendPoint _fromDoctorPoint(DoctorTrendPoint p) => TrendPoint(
        dayKey: p.dayKey,
        date: p.date,
        total: p.total,
        completed: p.completed,
        cancelled: p.cancelled,
      );
}
