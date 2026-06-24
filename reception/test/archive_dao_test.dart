import 'package:aarvy_reception/db/app_database.dart';
import 'package:aarvy_reception/db/archive_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ArchiveDao dao;

  setUp(() async {
    db = await AppDatabase.openInMemoryForTesting();
    dao = ArchiveDao(db);
  });

  tearDown(() async => db.close());

  test('archiveAll is idempotent on appointment id', () async {
    final batch = [
      appt(id: 'a1', dayKey: '2026-06-20'),
      appt(id: 'a2', dayKey: '2026-06-20', status: 2),
    ];
    expect(await dao.archiveAll(batch), 2);
    // Re-archiving the same day replaces rather than duplicating.
    expect(await dao.archiveAll(batch), 2);
    expect(await dao.countForDay('2026-06-20'), 2);
  });

  test('search matches patient name, phone, doctor and token', () async {
    await dao.archiveAll([
      appt(id: 'a1', dayKey: '2026-06-20', patientName: 'Anita Sharma'),
      appt(
          id: 'a2',
          dayKey: '2026-06-20',
          patientName: 'Bobby Singh',
          patientPhone: '9123456780',
          tokenNumber: 42),
    ]);

    expect((await dao.search(q: 'anita')).total, 1);
    expect((await dao.search(q: '9123456780')).total, 1);
    expect((await dao.search(q: '42')).total, 1);
    expect((await dao.search(q: 'Dr. Asha')).total, 2);
    expect((await dao.search(q: 'nobody')).total, 0);
  });

  test('search filters by day and status with pagination', () async {
    await dao.archiveAll([
      for (var i = 0; i < 5; i++)
        appt(id: 'x$i', dayKey: '2026-06-19', status: 1),
      for (var i = 0; i < 3; i++)
        appt(id: 'y$i', dayKey: '2026-06-20', status: 2),
    ]);

    expect((await dao.search(dayKey: '2026-06-19')).total, 5);
    expect((await dao.search(status: 2)).total, 3);

    final page1 = await dao.search(dayKey: '2026-06-19', page: 1, limit: 2);
    expect(page1.rows.length, 2);
    expect(page1.total, 5);
    final page3 = await dao.search(dayKey: '2026-06-19', page: 3, limit: 2);
    expect(page3.rows.length, 1); // remainder
  });

  test('countsForDay aggregates completed/cancelled/walk-ins/revenue', () async {
    await dao.archiveAll([
      appt(id: 'c1', dayKey: '2026-06-20', status: 1, fee: 500),
      appt(id: 'c2', dayKey: '2026-06-20', status: 1, fee: 300, source: 'walk_in'),
      appt(id: 'c3', dayKey: '2026-06-20', status: 2, fee: 500),
      appt(id: 'c4', dayKey: '2026-06-20', status: 0, fee: 500),
    ]);

    final counts = await dao.countsForDay('2026-06-20');
    expect(counts.total, 4);
    expect(counts.completed, 2);
    expect(counts.cancelled, 1);
    expect(counts.upcoming, 1);
    expect(counts.walkIns, 1);
    expect(counts.revenue, 800); // only completed fees
  });

  test('archivedDays lists distinct days newest-first', () async {
    await dao.archiveAll([
      appt(id: 'a', dayKey: '2026-06-18'),
      appt(id: 'b', dayKey: '2026-06-20'),
      appt(id: 'c', dayKey: '2026-06-19'),
    ]);
    expect(await dao.archivedDays(), ['2026-06-20', '2026-06-19', '2026-06-18']);
  });

  test('daysBeyondRetention returns the oldest days past the window', () async {
    await dao.archiveAll([
      appt(id: 'a', dayKey: '2026-06-16'),
      appt(id: 'b', dayKey: '2026-06-17'),
      appt(id: 'c', dayKey: '2026-06-18'),
      appt(id: 'd', dayKey: '2026-06-19'),
    ]);
    // Keep 2 newest → 06-19, 06-18; prune 06-17, 06-16.
    expect(await dao.daysBeyondRetention(2), ['2026-06-17', '2026-06-16']);
    expect(await dao.daysBeyondRetention(10), isEmpty);
  });
}
