import 'package:flutter/foundation.dart';

import '../models/day_state.dart';
import '../services/eod_service.dart';
import 'services.dart';

enum EodRunStatus { idle, running, done, failed }

/// UI-facing wrapper around [EodService]: discovers days needing end-of-day
/// processing, runs the archive → summarize → purge job, and streams live
/// progress into a log the EOD screen renders.
class EodProvider extends ChangeNotifier {
  final Services _services;
  EodProvider(this._services);

  EodRunStatus _status = EodRunStatus.idle;
  final List<EodProgress> _log = [];
  List<String> _eligible = const [];
  List<DayState> _history = const [];
  String? _todayDayKey;
  String? _error;
  String? _activeDay;

  EodRunStatus get status => _status;
  List<EodProgress> get log => List.unmodifiable(_log);
  List<String> get eligibleDays => List.unmodifiable(_eligible);
  List<DayState> get history => List.unmodifiable(_history);
  String? get todayDayKey => _todayDayKey;
  String? get error => _error;
  String? get activeDay => _activeDay;
  bool get isRunning => _status == EodRunStatus.running;
  bool get hasPending => _eligible.isNotEmpty;

  /// Refresh the eligible-day list (cloud backlog + unfinished local states)
  /// and the local EOD history. [todayDayKey] is the server's authoritative
  /// clinic day (from the dashboard's `/stats/today`).
  Future<void> refresh(String todayDayKey) async {
    _todayDayKey = todayDayKey;
    _error = null;
    try {
      _eligible = await _services.eod.eligibleDays(todayDayKey);
    } on Exception catch (e) {
      _error = e.toString();
      _eligible = const [];
    }
    _history = await _services.dayStates.all();
    notifyListeners();
  }

  /// Run the full EOD job for every eligible day, oldest first. Stops at the
  /// first failure (e.g. the network dropped) so nothing cascades.
  Future<void> runAll() async {
    final today = _todayDayKey;
    if (today == null || _status == EodRunStatus.running) return;
    _status = EodRunStatus.running;
    _log.clear();
    _error = null;
    notifyListeners();

    final results = await _services.eod.runEligible(today, report: _onProgress);
    await _exportProcessed(results);

    _history = await _services.dayStates.all();
    _eligible = await _services.eod.eligibleDays(today);
    _activeDay = null;

    final allOk = results.every((r) => r.success);
    _status = results.isEmpty
        ? EodRunStatus.done
        : (allOk ? EodRunStatus.done : EodRunStatus.failed);
    if (!allOk) {
      _error = results.firstWhere((r) => !r.success).error;
    }
    notifyListeners();
  }

  /// Run EOD for one specific day (manual retry from the history list).
  Future<void> runDay(String dayKey) async {
    final today = _todayDayKey;
    if (today == null || _status == EodRunStatus.running) return;
    _status = EodRunStatus.running;
    _error = null;
    notifyListeners();

    final result =
        await _services.eod.runDay(dayKey, todayDayKey: today, report: _onProgress);
    await _exportProcessed([result]);

    _history = await _services.dayStates.all();
    _eligible = await _services.eod.eligibleDays(today);
    _activeDay = null;
    _status = result.success ? EodRunStatus.done : EodRunStatus.failed;
    if (!result.success) _error = result.error;
    notifyListeners();
  }

  void _onProgress(EodProgress p) {
    _activeDay = p.dayKey;
    _log.add(p);
    notifyListeners();
  }

  /// After EOD runs, write each archived day's register CSV into the folder
  /// configured in Settings. Days that never reached the archive stage (e.g. a
  /// run that failed before archiving) are skipped. A missing folder is a no-op
  /// with a single note in the log — EOD itself still succeeded.
  Future<void> _exportProcessed(List<EodDayResult> results) async {
    final folder = _services.settings.exportFolderPath;
    if (folder == null || folder.isEmpty) {
      if (results.any((r) => r.state.stage.reached(EodStage.archived))) {
        _onProgress(const EodProgress(
          dayKey: '—',
          stage: EodStage.archived,
          message: 'No export folder set in Settings — CSV not written.',
        ));
      }
      return;
    }
    for (final r in results) {
      if (!r.state.stage.reached(EodStage.archived)) continue;
      await _exportOne(r.dayKey, folder);
    }
  }

  Future<void> _exportOne(String dayKey, String folder) async {
    try {
      final res = await _services.backup.exportDayCsvToFolder(dayKey, folder);
      _onProgress(EodProgress(
        dayKey: dayKey,
        stage: EodStage.archived,
        message: 'Saved ${res.rows} record(s) to ${res.path}',
        archived: res.rows,
      ));
    } catch (e) {
      _onProgress(EodProgress(
        dayKey: dayKey,
        stage: EodStage.archived,
        message: 'CSV export failed: $e',
        isError: true,
      ));
    }
  }

  /// Re-export a single completed day's register CSV to the configured folder,
  /// without re-running the EOD ladder. Returns false if no folder is set.
  Future<bool> exportDayCsv(String dayKey) async {
    final folder = _services.settings.exportFolderPath;
    if (folder == null || folder.isEmpty) return false;
    await _exportOne(dayKey, folder);
    return true;
  }

  void clearLog() {
    _log.clear();
    _status = EodRunStatus.idle;
    notifyListeners();
  }
}
