import '../api/api_client.dart';
import '../api/appointment_api.dart';
import '../api/auth_api.dart';
import '../api/doctor_api.dart';
import '../api/health_api.dart';
import '../api/stats_api.dart';
import '../api/summary_api.dart';
import '../db/app_database.dart';
import '../db/archive_dao.dart';
import '../db/backup_service.dart';
import '../db/day_state_dao.dart';
import '../services/eod_service.dart';
import 'settings_store.dart';

/// Composition root — constructs and holds the shared singletons (API client,
/// per-resource APIs, DAOs, services). Providers read their collaborators from
/// here so wiring stays in one place and tests can swap pieces out.
class Services {
  final SettingsStore settings;
  final ApiClient api;

  final AuthApi auth;
  final DoctorApi doctors;
  final AppointmentApi appointments;
  final StatsApi stats;
  final SummaryApi summaries;
  final HealthApi health;

  final ArchiveDao archive;
  final DayStateDao dayStates;
  final BackupService backup;
  final EodService eod;

  Services._({
    required this.settings,
    required this.api,
    required this.auth,
    required this.doctors,
    required this.appointments,
    required this.stats,
    required this.summaries,
    required this.health,
    required this.archive,
    required this.dayStates,
    required this.backup,
    required this.eod,
  });

  /// Build the whole graph. Call after [AppDatabase.open] and
  /// [SettingsStore.load]. The database must already be open.
  factory Services.wire({
    required SettingsStore settings,
    required AppDatabase database,
  }) {
    final api = ApiClient(baseUrl: settings.baseUrl)..token = settings.token;

    final archive = ArchiveDao(database.db);
    final dayStates = DayStateDao(database.db);
    final appointments = AppointmentApi(api);
    final summaries = SummaryApi(api);

    return Services._(
      settings: settings,
      api: api,
      auth: AuthApi(api),
      doctors: DoctorApi(api),
      appointments: appointments,
      stats: StatsApi(api),
      summaries: summaries,
      health: HealthApi(api),
      archive: archive,
      dayStates: dayStates,
      backup: BackupService(archive),
      eod: EodService(
        appointments: appointments,
        summaries: summaries,
        archive: archive,
        dayStates: dayStates,
      ),
    );
  }
}
