import 'package:aarvy_reception/api/api_client.dart';
import 'package:aarvy_reception/api/appointment_api.dart';
import 'package:aarvy_reception/api/summary_api.dart';
import 'package:aarvy_reception/db/app_database.dart';
import 'package:aarvy_reception/db/archive_dao.dart';
import 'package:aarvy_reception/db/day_state_dao.dart';
import 'package:aarvy_reception/models/day_state.dart';
import 'package:aarvy_reception/services/eod_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// An ApiClient stand-in that serves canned appointment pages and records the
/// purge/summarize calls the EOD job makes. Models the backend's contract:
/// a day's records exist until purged, after which the cloud returns empty.
class FakeApiClient extends ApiClient {
  /// dayKey -> list of appointment JSON maps still "in the cloud".
  final Map<String, List<Map<String, dynamic>>> cloud;
  final List<String> summarized = [];
  final List<String> purged = [];
  bool failPurge = false;

  FakeApiClient(this.cloud) : super(baseUrl: 'http://test/api');

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/appointments') {
      final date = query?['date'] as String?;
      final to = query?['to'] as String?;
      final page = (query?['page'] ?? 1) as int;
      final limit = (query?['limit'] ?? 50) as int;

      Iterable<MapEntry<String, List<Map<String, dynamic>>>> entries =
          cloud.entries;
      if (date != null) entries = entries.where((e) => e.key == date);
      if (to != null) entries = entries.where((e) => e.key.compareTo(to) <= 0);

      final all = entries.expand((e) => e.value).toList();
      final start = (page - 1) * limit;
      final slice =
          start >= all.length ? <Map<String, dynamic>>[] : all.skip(start).take(limit).toList();
      return {'data': slice, 'page': page, 'limit': limit, 'total': all.length};
    }
    throw UnimplementedError('GET $path');
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    if (path == '/summaries') {
      final dayKey = (body as Map)['dayKey'] as String;
      summarized.add(dayKey);
      return <String, dynamic>{
        'dayKey': dayKey,
        'date': '${dayKey}T00:00:00.000Z',
        'overall': <String, dynamic>{},
        'perDoctor': <dynamic>[],
      };
    }
    throw UnimplementedError('POST $path');
  }

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    if (path == '/appointments') {
      if (failPurge) throw const ApiClientTestError('purge failed');
      final date = query?['date'] as String;
      final removed = cloud.remove(date)?.length ?? 0;
      purged.add(date);
      return {'deleted': removed};
    }
    throw UnimplementedError('DELETE $path');
  }
}

class ApiClientTestError implements Exception {
  final String message;
  const ApiClientTestError(this.message);
  @override
  String toString() => message;
}

Map<String, dynamic> apptJson(String id, String dayKey, {int status = 1}) => {
      'id': id,
      'doctorId': 'd1',
      'doctorName': 'Dr. Asha Rao',
      'doctorPhotoUrl': '',
      'specialtyName': 'Cardiology',
      'hospitalName': 'Aarvy Hospital',
      'dateTime': '${dayKey}T10:30:00.000Z',
      'slotLabel': '10:30 AM',
      'fee': 500,
      'paymentMethod': 1,
      'status': status,
      'reviewed': false,
      'dayKey': dayKey,
      'patientName': 'Patient $id',
      'patientPhone': '9990001112',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ArchiveDao archive;
  late DayStateDao dayStates;
  DateTime clock() => DateTime.parse('2026-06-23T20:00:00');

  setUp(() async {
    db = await AppDatabase.openInMemoryForTesting();
    archive = ArchiveDao(db);
    dayStates = DayStateDao(db);
  });

  tearDown(() async => db.close());

  EodService buildService(FakeApiClient api) => EodService(
        appointments: AppointmentApi(api),
        summaries: SummaryApi(api),
        archive: archive,
        dayStates: dayStates,
        now: clock,
      );

  test('runDay archives, summarizes, then purges a past day', () async {
    final api = FakeApiClient({
      '2026-06-20': [apptJson('a1', '2026-06-20'), apptJson('a2', '2026-06-20', status: 2)],
    });
    final eod = buildService(api);

    final result = await eod.runDay('2026-06-20', todayDayKey: '2026-06-23');

    expect(result.success, isTrue);
    expect(result.state.stage, EodStage.purged);
    // Local archive now holds the full records permanently.
    expect(await archive.countForDay('2026-06-20'), 2);
    // Cloud summarized then purged.
    expect(api.summarized, ['2026-06-20']);
    expect(api.purged, ['2026-06-20']);
    expect(api.cloud.containsKey('2026-06-20'), isFalse);
  });

  test('refuses to process today or a future day', () async {
    final api = FakeApiClient({'2026-06-23': [apptJson('t1', '2026-06-23', status: 0)]});
    final eod = buildService(api);

    final result = await eod.runDay('2026-06-23', todayDayKey: '2026-06-23');
    expect(result.success, isFalse);
    expect(api.summarized, isEmpty);
    expect(api.purged, isEmpty);
  });

  test('is idempotent and resumable — re-running a purged day is a no-op', () async {
    final api = FakeApiClient({
      '2026-06-20': [apptJson('a1', '2026-06-20')],
    });
    final eod = buildService(api);

    await eod.runDay('2026-06-20', todayDayKey: '2026-06-23');
    // Second run: cloud already empty; stages already purged.
    final second = await eod.runDay('2026-06-20', todayDayKey: '2026-06-23');
    expect(second.success, isTrue);
    expect(second.state.stage, EodStage.purged);
    // No duplicate summarize/purge beyond the first.
    expect(api.summarized.length, 1);
    expect(api.purged.length, 1);
  });

  test('resumes from summarized stage after a purge failure', () async {
    final api = FakeApiClient({
      '2026-06-20': [apptJson('a1', '2026-06-20')],
    })..failPurge = true;
    final eod = buildService(api);

    final first = await eod.runDay('2026-06-20', todayDayKey: '2026-06-23');
    expect(first.success, isFalse);
    expect(first.state.stage, EodStage.summarized); // got past summarize
    expect(api.cloud.containsKey('2026-06-20'), isTrue); // not purged

    // Recover and retry — only the purge step should run now.
    api.failPurge = false;
    final retry = await eod.runDay('2026-06-20', todayDayKey: '2026-06-23');
    expect(retry.success, isTrue);
    expect(retry.state.stage, EodStage.purged);
    expect(api.summarized.length, 1); // summarize not repeated
    expect(api.purged, ['2026-06-20']);
  });

  test('eligibleDays surfaces past cloud days only', () async {
    final api = FakeApiClient({
      '2026-06-19': [apptJson('a', '2026-06-19')],
      '2026-06-20': [apptJson('b', '2026-06-20')],
      '2026-06-23': [apptJson('c', '2026-06-23', status: 0)], // today
    });
    final eod = buildService(api);

    final days = await eod.eligibleDays('2026-06-23');
    expect(days, ['2026-06-19', '2026-06-20']);
  });

  test('runEligible processes every past day oldest-first', () async {
    final api = FakeApiClient({
      '2026-06-19': [apptJson('a', '2026-06-19')],
      '2026-06-20': [apptJson('b', '2026-06-20')],
    });
    final eod = buildService(api);

    final results = await eod.runEligible('2026-06-23');
    expect(results.length, 2);
    expect(results.every((r) => r.success), isTrue);
    expect(api.purged, ['2026-06-19', '2026-06-20']);
  });
}
