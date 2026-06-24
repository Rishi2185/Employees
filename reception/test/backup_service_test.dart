import 'package:aarvy_reception/db/app_database.dart';
import 'package:aarvy_reception/db/archive_dao.dart';
import 'package:aarvy_reception/db/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ArchiveDao dao;
  late BackupService backup;

  setUp(() async {
    db = await AppDatabase.openInMemoryForTesting();
    dao = ArchiveDao(db);
    backup = BackupService(dao);
  });

  tearDown(() async => db.close());

  test('CSV has a header row plus one line per record', () {
    final csv = backup.buildCsv([
      appt(id: 'a1', dayKey: '2026-06-20', patientName: 'Anita'),
      appt(id: 'a2', dayKey: '2026-06-20', patientName: 'Bobby'),
    ]);
    final lines = csv.trim().split('\n');
    expect(lines.length, 3); // header + 2
    expect(lines.first, BackupService.csvHeaders.join(','));
    expect(lines[1], contains('Anita'));
  });

  test('CSV escapes commas and quotes per RFC-4180', () {
    final csv = backup.buildCsv([
      appt(id: 'a1', dayKey: '2026-06-20', patientName: 'Doe, John "JD"'),
    ]);
    // Embedded comma + quotes → field wrapped in quotes, inner quotes doubled.
    expect(csv, contains('"Doe, John ""JD"""'));
  });

  test('status and payment render as labels, not raw ints', () {
    final csv = backup.buildCsv([
      appt(id: 'a1', dayKey: '2026-06-20', status: 1),
    ]);
    expect(csv, contains('Completed'));
    expect(csv, contains('UPI'));
  });
}
