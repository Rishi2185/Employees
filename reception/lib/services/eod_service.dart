import '../api/appointment_api.dart';
import '../api/summary_api.dart';
import '../db/archive_dao.dart';
import '../db/day_state_dao.dart';
import '../models/day_state.dart';
import '../models/reception_appointment.dart';
import '../utils/day_key.dart';

/// A single progress event emitted while the end-of-day job runs, so the UI can
/// show a live, stage-by-stage view.
class EodProgress {
  final String dayKey;
  final EodStage stage; // the stage just completed (or being attempted)
  final String message;
  final bool isError;
  final int archived;
  final int purged;

  const EodProgress({
    required this.dayKey,
    required this.stage,
    required this.message,
    this.isError = false,
    this.archived = 0,
    this.purged = 0,
  });
}

/// The outcome of processing one day.
class EodDayResult {
  final String dayKey;
  final DayState state;
  final bool success;
  final String? error;
  const EodDayResult(this.dayKey, this.state, this.success, [this.error]);
}

typedef EodReporter = void Function(EodProgress);

/// The end-of-day **archive → summarize → purge** state machine.
///
/// Contract (mirrors the backend README's EOD section):
///  1. PULL   `GET /appointments?date=<dayKey>` → write full records to the
///            local archive (pure read; safe to retry).
///  2. SUMMARIZE `POST /summaries {dayKey}` → the *server* computes counts and
///            upserts the summary. Reception never supplies counts.
///  3. PURGE  `DELETE /appointments?date&confirm` → delete the day's cloud
///            records. Gated server-side: summary must exist, day strictly past.
///
/// Every step is **idempotent** and the local [DayState] records the furthest
/// stage durably reached, so a crash or network drop resumes from there instead
/// of repeating a destructive action. Purging a day whose records are already
/// gone returns `{deleted: 0}` and still completes the day.
class EodService {
  final AppointmentApi _appointments;
  final SummaryApi _summaries;
  final ArchiveDao _archive;
  final DayStateDao _dayStates;

  /// Injectable clock so tests don't depend on the wall clock.
  final DateTime Function() _now;

  EodService({
    required AppointmentApi appointments,
    required SummaryApi summaries,
    required ArchiveDao archive,
    required DayStateDao dayStates,
    DateTime Function()? now,
  })  : _appointments = appointments,
        _summaries = summaries,
        _archive = archive,
        _dayStates = dayStates,
        _now = now ?? DateTime.now;

  /// Discover every past day that still needs end-of-day processing.
  ///
  /// Sources, unioned:
  ///  - cloud appointments strictly before [todayDayKey] (leftover records that
  ///    were never archived), and
  ///  - locally-recorded day-states that haven't reached `purged`.
  /// Returns dayKeys in chronological (oldest-first) order — process the oldest
  /// backlog first.
  Future<List<String>> eligibleDays(String todayDayKey) async {
    final days = <String>{};

    // Leftover cloud records before today.
    final yesterday = DayKey.previous(todayDayKey);
    var page = 1;
    while (true) {
      final res = await _appointments.list(to: yesterday, page: page, limit: 100);
      for (final a in res.data) {
        if (DayKey.isBefore(a.dayKey, todayDayKey)) days.add(a.dayKey);
      }
      if (res.data.isEmpty || page * res.limit >= res.total) break;
      page++;
    }

    // Unfinished local day-states (e.g. summarized-but-not-purged after a crash).
    for (final s in await _dayStates.unfinished()) {
      if (DayKey.isBefore(s.dayKey, todayDayKey)) days.add(s.dayKey);
    }

    final sorted = days.toList()..sort();
    return sorted;
  }

  /// Run (or resume) the full EOD ladder for a single past day. Safe to call
  /// repeatedly; already-completed stages are skipped.
  Future<EodDayResult> runDay(
    String dayKey, {
    required String todayDayKey,
    EodReporter? report,
  }) async {
    // Guard: never EOD-process today or a future day (the cloud still needs it).
    if (!DayKey.isBefore(dayKey, todayDayKey)) {
      final state = await _dayStates.getOrCreate(dayKey, now: _now());
      const msg = 'Skipped: day is not strictly in the past.';
      report?.call(EodProgress(
          dayKey: dayKey, stage: state.stage, message: msg, isError: true));
      return EodDayResult(dayKey, state, false, msg);
    }

    var state = await _dayStates.getOrCreate(dayKey, now: _now());

    try {
      // ---- 1. ARCHIVE ----
      if (!state.stage.reached(EodStage.archived)) {
        final count = await _archiveDay(dayKey);
        state = await _dayStates.markArchived(dayKey, count: count, now: _now());
        report?.call(EodProgress(
          dayKey: dayKey,
          stage: EodStage.archived,
          message: 'Archived $count record(s) locally.',
          archived: count,
        ));
      } else {
        report?.call(EodProgress(
          dayKey: dayKey,
          stage: EodStage.archived,
          message: 'Already archived (${state.archivedCount}).',
          archived: state.archivedCount,
        ));
      }

      // ---- 2. SUMMARIZE ----
      if (!state.stage.reached(EodStage.summarized)) {
        await _summaries.write(dayKey);
        state = await _dayStates.markSummarized(dayKey, now: _now());
        report?.call(EodProgress(
          dayKey: dayKey,
          stage: EodStage.summarized,
          message: 'Daily summary written to the cloud.',
        ));
      } else {
        report?.call(EodProgress(
          dayKey: dayKey,
          stage: EodStage.summarized,
          message: 'Summary already written.',
        ));
      }

      // ---- 3. PURGE ----
      if (!state.stage.reached(EodStage.purged)) {
        final deleted = await _appointments.purgeDay(dayKey);
        state = await _dayStates.markPurged(dayKey, purged: deleted, now: _now());
        report?.call(EodProgress(
          dayKey: dayKey,
          stage: EodStage.purged,
          message: 'Purged $deleted cloud record(s). Day complete.',
          purged: deleted,
        ));
      }

      return EodDayResult(dayKey, state, true);
    } catch (e) {
      final msg = e.toString();
      state = await _dayStates.markError(dayKey, msg, now: _now());
      report?.call(EodProgress(
        dayKey: dayKey,
        stage: state.stage,
        message: msg,
        isError: true,
      ));
      return EodDayResult(dayKey, state, false, msg);
    }
  }

  /// Process every eligible day in order, stopping at the first failure so a
  /// transient error (e.g. offline) doesn't cascade. Returns each day's result.
  Future<List<EodDayResult>> runEligible(
    String todayDayKey, {
    EodReporter? report,
  }) async {
    final results = <EodDayResult>[];
    for (final day in await eligibleDays(todayDayKey)) {
      final r = await runDay(day, todayDayKey: todayDayKey, report: report);
      results.add(r);
      if (!r.success) break;
    }
    return results;
  }

  /// Pull every page of a day's cloud records and write them to the archive.
  Future<int> _archiveDay(String dayKey) async {
    final all = <ReceptionAppointment>[];
    var page = 1;
    while (true) {
      final res =
          await _appointments.list(date: dayKey, page: page, limit: 100);
      all.addAll(res.data);
      if (res.data.isEmpty || page * res.limit >= res.total) break;
      page++;
    }
    if (all.isEmpty) {
      // Nothing in the cloud for this day. If we already have a local archive
      // (e.g. purge ran but the marker was lost), keep that count; else 0.
      return _archive.countForDay(dayKey);
    }
    return _archive.archiveAll(all);
  }
}
