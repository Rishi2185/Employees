import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/day_state.dart';
import 'app_database.dart';

/// Persists end-of-day progress per clinic day so the archive → summarize →
/// purge job survives restarts and never repeats a destructive step.
///
/// The DAO only records *facts* (which stage a day has durably reached); the
/// EodService owns the decision of what to do next given those facts.
class DayStateDao {
  final Database _db;
  DayStateDao(this._db);

  factory DayStateDao.standalone() => DayStateDao(AppDatabase.instance.db);

  static const _table = 'day_state';

  Future<DayState?> get(String dayKey) async {
    final rows = await _db
        .query(_table, where: 'day_key = ?', whereArgs: [dayKey], limit: 1);
    if (rows.isEmpty) return null;
    return DayState.fromDbMap(rows.first);
  }

  /// Get the existing state or a fresh `pending` one (not yet persisted).
  Future<DayState> getOrCreate(String dayKey, {required DateTime now}) async {
    return await get(dayKey) ??
        DayState(dayKey: dayKey, stage: EodStage.pending, updatedAt: now);
  }

  Future<void> save(DayState state) async {
    await _db.insert(_table, state.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Mark the archive step complete: rows are durably in the local archive.
  Future<DayState> markArchived(String dayKey,
      {required int count, required DateTime now}) async {
    final cur = await getOrCreate(dayKey, now: now);
    final next = cur.copyWith(
      stage: cur.stage.reached(EodStage.archived) ? cur.stage : EodStage.archived,
      archivedCount: count,
      archivedAt: now,
      updatedAt: now,
      clearError: true,
    );
    await save(next);
    return next;
  }

  Future<DayState> markSummarized(String dayKey, {required DateTime now}) async {
    final cur = await getOrCreate(dayKey, now: now);
    final next = cur.copyWith(
      stage: cur.stage.reached(EodStage.summarized)
          ? cur.stage
          : EodStage.summarized,
      summarizedAt: now,
      updatedAt: now,
      clearError: true,
    );
    await save(next);
    return next;
  }

  Future<DayState> markPurged(String dayKey,
      {required int purged, required DateTime now}) async {
    final cur = await getOrCreate(dayKey, now: now);
    final next = cur.copyWith(
      stage: EodStage.purged,
      purgedCount: purged,
      purgedAt: now,
      updatedAt: now,
      clearError: true,
    );
    await save(next);
    return next;
  }

  /// Record a failure against the day without advancing the stage, so the UI
  /// can show what went wrong and the job can be retried.
  Future<DayState> markError(String dayKey, String error,
      {required DateTime now}) async {
    final cur = await getOrCreate(dayKey, now: now);
    final next = cur.copyWith(lastError: error, updatedAt: now);
    await save(next);
    return next;
  }

  /// All day-states, newest first (drives the EOD history list).
  Future<List<DayState>> all() async {
    final rows = await _db.query(_table, orderBy: 'day_key DESC');
    return rows.map(DayState.fromDbMap).toList();
  }

  /// Days that have started but not finished the EOD ladder — resume targets.
  Future<List<DayState>> unfinished() async {
    final rows = await _db.query(_table,
        where: 'stage != ?', whereArgs: [EodStage.purged.name],
        orderBy: 'day_key ASC');
    return rows.map(DayState.fromDbMap).toList();
  }
}
