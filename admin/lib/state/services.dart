import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/doctor_api.dart';
import '../api/health_api.dart';
import '../api/imagekit_service.dart';
import '../api/meta_api.dart';
import '../api/stats_api.dart';
import '../api/summary_api.dart';
import 'settings_store.dart';

/// Composition root for the admin app — constructs the API client and the
/// per-resource APIs once, and hands them to the providers.
class Services {
  final SettingsStore settings;
  final ApiClient api;

  final AuthApi auth;
  final DoctorApi doctors;
  final StatsApi stats;
  final SummaryApi summaries;
  final MetaApi meta;
  final HealthApi health;
  final ImageKitService imagekit;

  Services._({
    required this.settings,
    required this.api,
    required this.auth,
    required this.doctors,
    required this.stats,
    required this.summaries,
    required this.meta,
    required this.health,
    required this.imagekit,
  });

  /// Build the graph. Pass [apiOverride] in tests to inject a fake client.
  factory Services.wire({required SettingsStore settings, ApiClient? apiOverride}) {
    final api =
        apiOverride ?? (ApiClient(baseUrl: settings.baseUrl)..token = settings.token);
    return Services._(
      settings: settings,
      api: api,
      auth: AuthApi(api),
      doctors: DoctorApi(api),
      stats: StatsApi(api),
      summaries: SummaryApi(api),
      meta: MetaApi(api),
      health: HealthApi(api),
      imagekit: ImageKitService(api),
    );
  }
}
