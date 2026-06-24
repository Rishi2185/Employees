import 'package:aarvy_reception/db/app_database.dart';
import 'package:aarvy_reception/db/day_state_dao.dart';
import 'package:aarvy_reception/models/day_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late DayStateDao dao;
  final now = DateTime.parse('2026-06-23T20:00:00');

  setUp(() async {
    db = await AppDatabase.openInMemoryForTesting();
    dao = DayStateDao(db);
  });

  tearDown(() async => db.close());

  test('stages advance forward and never regress', () async {
    await dao.markArchived('2026-06-20', count: 7, now: now);
    var s = await dao.get('2026-06-20');
    expect(s!.stage, EodStage.archived);
    expect(s.archivedCount, 7);

    await dao.markSummarized('2026-06-20', now: now);
    s = await dao.get('2026-06-20');
    expect(s!.stage, EodStage.summarized);

    // Re-marking an earlier stage must not pull the ladder backwards.
    await dao.markArchived('2026-06-20', count: 7, now: now);
    s = await dao.get('2026-06-20');
    expect(s!.stage, EodStage.summarized);

    await dao.markPurged('2026-06-20', purged: 7, now: now);
    s = await dao.get('2026-06-20');
    expect(s!.stage, EodStage.purged);
    expect(s.isDone, isTrue);
  });

  test('markError records the message without advancing the stage', () async {
    await dao.markArchived('2026-06-20', count: 3, now: now);
    await dao.markError('2026-06-20', 'network down', now: now);
    final s = await dao.get('2026-06-20');
    expect(s!.stage, EodStage.archived);
    expect(s.lastError, 'network down');
  });

  test('advancing a stage clears a prior error', () async {
    await dao.markArchived('2026-06-20', count: 3, now: now);
    await dao.markError('2026-06-20', 'boom', now: now);
    await dao.markSummarized('2026-06-20', now: now);
    final s = await dao.get('2026-06-20');
    expect(s!.lastError, isNull);
  });

  test('unfinished returns only days not yet purged', () async {
    await dao.markPurged('2026-06-18', purged: 2, now: now);
    await dao.markArchived('2026-06-19', count: 4, now: now);
    await dao.markSummarized('2026-06-20', now: now);

    final unfinished = await dao.unfinished();
    final keys = unfinished.map((e) => e.dayKey).toList();
    expect(keys, containsAll(['2026-06-19', '2026-06-20']));
    expect(keys, isNot(contains('2026-06-18')));
  });
}
