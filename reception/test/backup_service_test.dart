import 'dart:io';

import 'package:aarvy_reception/db/app_database.dart';
import 'package:aarvy_reception/db/archive_dao.dart';
import 'package:aarvy_reception/db/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
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

  group('day register', () {
    test('header is the front-desk column set in order', () {
      final csv = backup.buildDayRegisterCsv([]);
      expect(csv.trim(), BackupService.dayRegisterHeaders.join(','));
      expect(BackupService.dayRegisterHeaders, [
        'S.No',
        'Patient Name',
        'Blood Group',
        'Patient Phone',
        'Doctor Name',
        'Payment Method',
        'Payment Status',
        'Appointment Status',
      ]);
    });

    test('rows are numbered 1..N and carry blood group + phone + doctor', () {
      final csv = backup.buildDayRegisterCsv([
        appt(
          id: 'a1',
          dayKey: '2026-06-20',
          patientName: 'Anita',
          patientPhone: '9990001112',
          patientBloodGroup: 'O+',
          doctorName: 'Dr. Asha Rao',
        ),
        appt(id: 'a2', dayKey: '2026-06-20', patientName: 'Bobby'),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3); // header + 2
      expect(lines[1], startsWith('1,Anita,O+,9990001112,Dr. Asha Rao,'));
      expect(lines[2], startsWith('2,Bobby,'));
    });

    test('payment status maps to Paid / Not paid / blank', () {
      String regRow(String? status) => backup
          .buildDayRegisterCsv([
            appt(id: 'a1', dayKey: '2026-06-20', paymentStatus: status),
          ])
          .trim()
          .split('\n')[1];
      expect(regRow('completed'), contains('Paid'));
      expect(regRow('pending'), contains('Not paid'));
      // Unset → empty Payment Status field (two consecutive separators before
      // the trailing Appointment Status label).
      expect(regRow(null), contains(',,Completed'));
    });

    test('exportDayCsvToFolder writes a derived file with the day register', () async {
      await dao.archiveAll([
        appt(id: 'a1', dayKey: '2026-06-20', patientName: 'Anita', patientBloodGroup: 'O+'),
      ]);
      final dir = await Directory.systemTemp.createTemp('aarvy_export_test');
      try {
        final res = await backup.exportDayCsvToFolder('2026-06-20', dir.path);
        expect(res.rows, 1);
        expect(res.path, p.join(dir.path, BackupService.suggestedCsvName('2026-06-20')));
        final written = await File(res.path).readAsString();
        expect(written, startsWith(BackupService.dayRegisterHeaders.join(',')));
        expect(written, contains('Anita'));
        expect(written, contains('O+'));
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
