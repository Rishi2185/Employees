import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/reception_appointment.dart';
import '../utils/status_ui.dart';
import 'app_database.dart';
import 'archive_dao.dart';

/// Export & backup of the durable local archive.
///
/// Two flavours:
///  - **CSV export** — human-readable, opens in Excel; for sharing a day or a
///    date range with management.
///  - **DB file backup** — a byte copy of the SQLite file (the entire long-term
///    record) for disaster recovery onto an external drive.
///
/// Both take an explicit destination path (chosen via a save dialog in the UI),
/// so this service has no UI dependency and is unit-testable.
class BackupService {
  final ArchiveDao _archive;
  BackupService(this._archive);

  factory BackupService.standalone() =>
      BackupService(ArchiveDao.standalone());

  /// CSV columns — stable order; PII included because this is the local record.
  static const List<String> csvHeaders = [
    'day_key',
    'date_time',
    'token_number',
    'patient_name',
    'patient_phone',
    'patient_age',
    'patient_gender',
    'doctor_name',
    'specialty_name',
    'slot_label',
    'status',
    'payment_method',
    'fee',
    'checked_in',
    'source',
    'created_by',
  ];

  String _row(ReceptionAppointment a) => [
        a.dayKey,
        a.dateTime.toIso8601String(),
        a.tokenNumber?.toString() ?? '',
        a.patientName ?? '',
        a.patientPhone ?? '',
        a.patientAge?.toString() ?? '',
        a.patientGender ?? '',
        a.doctorName,
        a.specialtyName,
        a.slotLabel,
        StatusUi.label(a.status),
        StatusUi.paymentLabel(a.paymentMethod),
        a.fee.toString(),
        a.checkedIn ? 'yes' : 'no',
        a.source ?? '',
        a.createdBy ?? '',
      ].map(_escape).join(',');

  /// RFC-4180 field escaping: wrap in quotes if the value contains a comma,
  /// quote, or newline, and double any embedded quotes.
  String _escape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n') ||
        v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  String buildCsv(List<ReceptionAppointment> rows) {
    final buf = StringBuffer()..writeln(csvHeaders.join(','));
    for (final a in rows) {
      buf.writeln(_row(a));
    }
    return buf.toString();
  }

  /// Export a single day's archive to [destPath] as CSV. Returns rows written.
  Future<int> exportDayCsv(String dayKey, String destPath) async {
    final rows = await _archive.forDay(dayKey);
    await _writeCsv(destPath, rows);
    return rows.length;
  }

  /// Export a date range (inclusive, by dayKey) to [destPath] as CSV.
  Future<int> exportRangeCsv(
      {String? from, String? to, required String destPath}) async {
    // Pull all matching rows (export is not paginated).
    final page =
        await _archive.search(from: from, to: to, page: 1, limit: 1 << 30);
    await _writeCsv(destPath, page.rows);
    return page.rows.length;
  }

  Future<void> _writeCsv(String destPath, List<ReceptionAppointment> rows) async {
    final file = File(destPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(buildCsv(rows), flush: true);
  }

  /// Copy the entire SQLite database file to [destPath] for offline backup.
  /// Returns the number of bytes written.
  Future<int> backupDatabase(String destPath) async {
    final src = AppDatabase.instance.path;
    if (src == null) {
      throw StateError('Database is not open; cannot back it up.');
    }
    final dest = File(destPath);
    await dest.parent.create(recursive: true);
    await File(src).copy(dest.path);
    return dest.lengthSync();
  }

  /// A sensible default file name for a backup, e.g.
  /// `aarvy_archive_backup_2026-06-23.db` (caller supplies the dayKey/stamp to
  /// avoid `DateTime.now()` ambiguity around midnight).
  static String suggestedBackupName(String stamp) =>
      'aarvy_archive_backup_$stamp.db';

  static String suggestedCsvName(String label) =>
      'aarvy_archive_${label.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.csv';

  /// Where the live DB currently lives (shown in Settings).
  static String? get databasePath => AppDatabase.instance.path;

  /// Directory portion of the DB path (for "open containing folder").
  static String? get databaseDir {
    final path = AppDatabase.instance.path;
    return path == null ? null : p.dirname(path);
  }
}
