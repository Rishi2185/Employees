import 'package:aarvy_admin/api/api_client.dart';
import 'package:aarvy_admin/api/doctor_api.dart';
import 'package:aarvy_admin/api/meta_api.dart';
import 'package:aarvy_admin/api/stats_api.dart';
import 'package:aarvy_admin/api/summary_api.dart';
import 'package:aarvy_admin/models/doctor_input.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records requests and returns canned JSON, so the API classes can be tested
/// without a live backend.
class FakeApiClient extends ApiClient {
  final List<String> calls = [];
  Object? lastBody;
  Map<String, dynamic>? lastQuery;

  FakeApiClient() : super(baseUrl: 'http://test/api');

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    calls.add('GET $path');
    lastQuery = query;
    switch (path) {
      case '/stats/live':
        return <String, dynamic>{
          'dayKey': '2026-06-23',
          'today': <String, dynamic>{
            'todaysAppointments': 3,
            'completed': 1,
            'pending': 2,
            'cancelled': 0,
            'walkIns': 1,
          },
          'perDoctor': <dynamic>[
            <String, dynamic>{'doctorId': 'd1', 'doctorName': 'Dr. A', 'total': 3, 'completed': 1, 'cancelled': 0, 'pending': 2},
          ],
          'future': <String, dynamic>{'upcoming': 5},
        };
      case '/summaries':
        if (query?['doctorId'] != null) {
          return <String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{'dayKey': '2026-06-20', 'date': '2026-06-20T00:00:00.000Z', 'doctorId': query!['doctorId'], 'total': 4, 'completed': 3, 'cancelled': 1, 'pending': 0},
            ],
            'count': 1,
          };
        }
        return <String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{
              'dayKey': '2026-06-20',
              'date': '2026-06-20T00:00:00.000Z',
              'overall': <String, dynamic>{'total': 9, 'completed': 7, 'cancelled': 2, 'pending': 0, 'walkIns': 1, 'revenue': 4500},
              'perDoctor': <dynamic>[],
            },
          ],
          'count': 1,
        };
      case '/specialties':
        return <String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{'id': 'cardiology', 'name': 'Cardiology'},
            <String, dynamic>{'id': 'derm', 'name': 'Dermatology'},
          ],
        };
      case '/doctors':
        return <String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{'id': 'd1', 'name': 'Dr. A', 'specialtyId': 's', 'specialtyName': 'S'},
          ],
          'page': 1,
          'limit': 100,
          'total': 1,
        };
    }
    throw UnimplementedError('GET $path');
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    calls.add('POST $path');
    lastBody = body;
    return <String, dynamic>{'id': 'doc_new', ...?(body as Map<String, dynamic>?)};
  }

  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    calls.add('PATCH $path');
    lastBody = body;
    return <String, dynamic>{'id': path.split('/').last, ...?(body as Map<String, dynamic>?)};
  }

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    calls.add('DELETE $path');
    return <String, dynamic>{'id': path.split('/').last, 'active': false};
  }
}

void main() {
  late FakeApiClient api;
  setUp(() => api = FakeApiClient());

  test('StatsApi.live parses the live payload', () async {
    final s = await StatsApi(api).live();
    expect(s.today.todaysAppointments, 3);
    expect(s.futureUpcoming, 5);
    expect(s.attended, 1);
    expect(api.calls, contains('GET /stats/live'));
  });

  test('SummaryApi.overall returns full per-day summaries', () async {
    final list = await SummaryApi(api).overall(from: '2026-06-01', to: '2026-06-23');
    expect(list, hasLength(1));
    expect(list.first.overall.total, 9);
    expect(list.first.overall.completed, 7);
    expect(api.lastQuery?['doctorId'], isNull);
  });

  test('SummaryApi.forDoctor returns flattened per-doctor points', () async {
    final list = await SummaryApi(api).forDoctor('d1', from: '2026-06-01', to: '2026-06-23');
    expect(list, hasLength(1));
    expect(list.first.doctorId, 'd1');
    expect(list.first.completed, 3);
    expect(api.lastQuery?['doctorId'], 'd1');
  });

  test('DoctorApi.create posts the full input and parses the result', () async {
    final input = DoctorInput(
        name: 'Dr. New', specialtyId: 'derm', specialtyName: 'Dermatology', consultationFee: 500);
    final doc = await DoctorApi(api).create(input);
    expect(api.calls, contains('POST /doctors'));
    expect((api.lastBody as Map)['name'], 'Dr. New');
    expect((api.lastBody as Map)['consultationFee'], 500);
    expect(doc.id, 'doc_new');
  });

  test('DoctorApi.update patches by id', () async {
    final input = DoctorInput(name: 'Dr. Edit', specialtyId: 's', specialtyName: 'S');
    final doc = await DoctorApi(api).update('d1', input);
    expect(api.calls, contains('PATCH /doctors/d1'));
    expect(doc.id, 'd1');
  });

  test('DoctorApi.deactivate returns the new active flag', () async {
    final active = await DoctorApi(api).deactivate('d1');
    expect(api.calls, contains('DELETE /doctors/d1'));
    expect(active, isFalse);
  });

  test('DoctorApi.list sends includeInactive only when true', () async {
    await DoctorApi(api).list(includeInactive: true);
    expect(api.lastQuery?['includeInactive'], 'true');
    await DoctorApi(api).list(includeInactive: false);
    expect(api.lastQuery?['includeInactive'], isNull);
  });

  test('MetaApi.specialties parses the reference list', () async {
    final specs = await MetaApi(api).specialties();
    expect(specs.map((s) => s.id), containsAll(['cardiology', 'derm']));
  });
}
