import 'package:aarvy_admin/api/api_client.dart';
import 'package:aarvy_admin/state/auth_provider.dart';
import 'package:aarvy_admin/state/services.dart';
import 'package:aarvy_admin/state/settings_store.dart';
import 'package:aarvy_admin/state/trends_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake client whose `/auth/login` returns a configurable role, and `/summaries`
/// returns two days of overall counts.
class FakeApiClient extends ApiClient {
  String role;
  FakeApiClient({this.role = 'admin'}) : super(baseUrl: 'http://test/api');

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    if (path == '/auth/login') {
      return <String, dynamic>{
        'token': 'tok_$role',
        'role': role,
        'displayName': 'Test $role',
        'userId': 'u1',
      };
    }
    throw UnimplementedError('POST $path');
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == '/summaries') {
      return <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'dayKey': '2026-06-20',
            'date': '2026-06-20T00:00:00.000Z',
            'overall': <String, dynamic>{'total': 10, 'completed': 8, 'cancelled': 2, 'pending': 0, 'walkIns': 0, 'revenue': 0},
            'perDoctor': <dynamic>[],
          },
          <String, dynamic>{
            'dayKey': '2026-06-21',
            'date': '2026-06-21T00:00:00.000Z',
            'overall': <String, dynamic>{'total': 4, 'completed': 3, 'cancelled': 1, 'pending': 0, 'walkIns': 0, 'revenue': 0},
            'perDoctor': <dynamic>[],
          },
        ],
        'count': 2,
      };
    }
    throw UnimplementedError('GET $path');
  }
}

Future<Services> buildServices(FakeApiClient api) async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsStore.load();
  return Services.wire(settings: settings, apiOverride: api);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider admin gate', () {
    test('accepts an admin login and persists the session', () async {
      final services = await buildServices(FakeApiClient(role: 'admin'));
      final auth = AuthProvider(services);
      final ok = await auth.login('admin', 'pw');
      expect(ok, isTrue);
      expect(auth.isSignedIn, isTrue);
      expect(services.settings.token, 'tok_admin');
    });

    test('rejects a reception login (admin-only app)', () async {
      final services = await buildServices(FakeApiClient(role: 'reception'));
      final auth = AuthProvider(services);
      final ok = await auth.login('reception', 'pw');
      expect(ok, isFalse);
      expect(auth.isSignedIn, isFalse);
      expect(auth.error, contains('administrators only'));
      // Non-admin token is never persisted.
      expect(services.settings.token, isNull);
    });
  });

  group('TrendsProvider', () {
    test('aggregates totals, average and peak over the loaded window', () async {
      final services = await buildServices(FakeApiClient());
      final trends = TrendsProvider(services);
      await trends.load();

      expect(trends.points, hasLength(2));
      expect(trends.totalAppointments, 14); // 10 + 4
      expect(trends.totalCompleted, 11); // 8 + 3
      expect(trends.peakDay, 10);
      expect(trends.avgPerDay, closeTo(7.0, 1e-9));
    });
  });
}
