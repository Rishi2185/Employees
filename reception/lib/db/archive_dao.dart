import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/reception_appointment.dart';
import 'app_database.dart';

/// A page of archived rows plus the total match count (for pagination UI).
class ArchivePage {
  final List<ReceptionAppointment> rows;
  final int total;
  const ArchivePage(this.rows, this.total);
}

/// One day's worth of aggregate counts, computed locally from the archive.
class ArchiveDayCounts {
  final String dayKey;
  final int total;
  final int completed;
  final int cancelled;
  final int upcoming;
  final int walkIns;
  final int revenue;
  const ArchiveDayCounts({
    required this.dayKey,
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.upcoming,
    required this.walkIns,
    required this.revenue,
  });
}

/// Reads/writes the durable `archived_appointments` table — the permanent
/// long-term record of every appointment the cloud has handed off at EOD.
///
/// All writes are idempotent on the appointment `id` (re-archiving a day is
/// safe), which is what makes the EOD job re-runnable.
class ArchiveDao {
  final Database _db;
  ArchiveDao(this._db);

  /// Convenience: use the singleton database.
  factory ArchiveDao.standalone() => ArchiveDao(AppDatabase.instance.db);

  static const _table = 'archived_appointments';

  /// Upsert a batch of appointments into the archive in one transaction.
  /// Returns the number of rows written. Safe to call repeatedly for a day.
  Future<int> archiveAll(List<ReceptionAppointment> appts) async {
    if (appts.isEmpty) return 0;
    final batch = _db.batch();
    for (final a in appts) {
      batch.insert(
        _table,
        a.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    final res = await batch.commit(noResult: false);
    return res.length;
  }

  /// Insert/replace a single archived appointment (e.g. an offline-saved
  /// walk-in or a manual correction).
  Future<void> upsert(ReceptionAppointment a) async {
    await _db.insert(_table, a.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReceptionAppointment?> getById(String id) async {
    final rows =
        await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return ReceptionAppointment.fromDbMap(rows.first);
  }

  /// How many rows are archived for a given day.
  Future<int> countForDay(String dayKey) async {
    final r = await _db.rawQuery(
        'SELECT COUNT(*) c FROM $_table WHERE day_key = ?', [dayKey]);
    return (r.first['c'] as int?) ?? 0;
  }

  /// Distinct days present in the archive, newest first.
  Future<List<String>> archivedDays() async {
    final r = await _db.rawQuery(
        'SELECT DISTINCT day_key FROM $_table ORDER BY day_key DESC');
    return r.map((e) => e['day_key'] as String).toList();
  }

  /// Full-text-ish search across patient name/phone, doctor, and specialty,
  /// with optional day / doctor / status filters. Paginated and indexed.
  Future<ArchivePage> search({
    String? q,
    String? dayKey,
    String? from,
    String? to,
    String? doctorId,
    int? status,
    int page = 1,
    int limit = 50,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (q != null && q.trim().isNotEmpty) {
      final like = '%${q.trim()}%';
      where.add('(patient_name LIKE ? OR patient_phone LIKE ? '
          'OR doctor_name LIKE ? OR specialty_name LIKE ? OR token_number = ?)');
      args.addAll([like, like, like, like, int.tryParse(q.trim())]);
    }
    if (dayKey != null) {
      where.add('day_key = ?');
      args.add(dayKey);
    }
    if (from != null) {
      where.add('day_key >= ?');
      args.add(from);
    }
    if (to != null) {
      where.add('day_key <= ?');
      args.add(to);
    }
    if (doctorId != null) {
      where.add('doctor_id = ?');
      args.add(doctorId);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }

    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final countRows = await _db
        .rawQuery('SELECT COUNT(*) c FROM $_table $whereSql', args);
    final total = (countRows.first['c'] as int?) ?? 0;

    final offset = (page - 1).clamp(0, 1 << 30) * limit;
    final rows = await _db.rawQuery(
      'SELECT * FROM $_table $whereSql ORDER BY date_time DESC LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );

    return ArchivePage(
      rows.map(ReceptionAppointment.fromDbMap).toList(),
      total,
    );
  }

  /// Rows for a single day, ordered by time (used for slip reprints / export).
  Future<List<ReceptionAppointment>> forDay(String dayKey) async {
    final rows = await _db.query(_table,
        where: 'day_key = ?', whereArgs: [dayKey], orderBy: 'date_time ASC');
    return rows.map(ReceptionAppointment.fromDbMap).toList();
  }

  /// Locally-computed counts for a day — the precise per-terminal source that
  /// overrides the cloud's derived "Total Patients" tile.
  Future<ArchiveDayCounts> countsForDay(String dayKey) async {
    final r = await _db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS completed,
        SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) AS cancelled,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) AS upcoming,
        SUM(CASE WHEN source = 'walk_in' THEN 1 ELSE 0 END) AS walk_ins,
        SUM(CASE WHEN status = 1 THEN fee ELSE 0 END) AS revenue
      FROM $_table WHERE day_key = ?
    ''', [dayKey]);
    final row = r.first;
    int n(String k) => (row[k] as int?) ?? 0;
    return ArchiveDayCounts(
      dayKey: dayKey,
      total: n('total'),
      completed: n('completed'),
      cancelled: n('cancelled'),
      upcoming: n('upcoming'),
      walkIns: n('walk_ins'),
      revenue: n('revenue'),
    );
  }

  /// Total archived rows across all days (drives the "Total Patients" tile,
  /// counting visits — matches the backend's semantics).
  Future<int> totalArchivedVisits() async {
    final r = await _db.rawQuery('SELECT COUNT(*) c FROM $_table');
    return (r.first['c'] as int?) ?? 0;
  }

  /// Delete the local archive for a day (used only by retention pruning of
  /// the *oldest* days beyond the configured window — never part of EOD).
  Future<int> deleteDay(String dayKey) async {
    return _db.delete(_table, where: 'day_key = ?', whereArgs: [dayKey]);
  }

  /// Days older than [keepDays] worth of distinct archived days, oldest first
  /// — candidates for retention pruning.
  Future<List<String>> daysBeyondRetention(int keepDays) async {
    final days = await archivedDays(); // newest first
    if (days.length <= keepDays) return const [];
    return days.sublist(keepDays); // the tail (oldest) beyond the window
  }
}
