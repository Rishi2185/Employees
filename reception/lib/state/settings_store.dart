import 'package:shared_preferences/shared_preferences.dart';

/// Persistent station settings, backed by `shared_preferences`.
///
/// This is a single trusted reception terminal, so the bearer token is kept
/// here too (the OS account + disk encryption is the trust boundary). Values
/// are read once at startup into memory and written through on change.
class SettingsStore {
  final SharedPreferences _prefs;
  SettingsStore(this._prefs);

  static Future<SettingsStore> load() async =>
      SettingsStore(await SharedPreferences.getInstance());

  // ---- keys ----
  static const _kBaseUrl = 'baseUrl';
  static const _kToken = 'authToken';
  static const _kSessionJson = 'authSession';
  static const _kRetentionDays = 'retentionDays';
  static const _kHospitalName = 'hospitalName';
  static const _kAutoEodPrompt = 'autoEodPrompt';

  static const String defaultBaseUrl = 'http://3.110.77.2:4000/api';
  static const int defaultRetentionDays = 365;

  String get baseUrl => _prefs.getString(_kBaseUrl) ?? defaultBaseUrl;
  Future<void> setBaseUrl(String v) => _prefs.setString(_kBaseUrl, v.trim());

  String? get token => _prefs.getString(_kToken);
  Future<void> setToken(String? v) async {
    if (v == null) {
      await _prefs.remove(_kToken);
    } else {
      await _prefs.setString(_kToken, v);
    }
  }

  /// The persisted auth session (raw JSON string) for silent re-login on boot.
  String? get sessionJson => _prefs.getString(_kSessionJson);
  Future<void> setSessionJson(String? v) async {
    if (v == null) {
      await _prefs.remove(_kSessionJson);
    } else {
      await _prefs.setString(_kSessionJson, v);
    }
  }

  /// How many days of full records to keep in the local archive. Beyond this,
  /// the oldest days are pruned (the cloud summary remains the history).
  int get retentionDays =>
      _prefs.getInt(_kRetentionDays) ?? defaultRetentionDays;
  Future<void> setRetentionDays(int v) =>
      _prefs.setInt(_kRetentionDays, v.clamp(7, 3650));

  String get hospitalName => _prefs.getString(_kHospitalName) ?? 'Aarvy Hospital';
  Future<void> setHospitalName(String v) =>
      _prefs.setString(_kHospitalName, v.trim());

  /// Whether to prompt the receptionist to run EOD when past-day records linger.
  bool get autoEodPrompt => _prefs.getBool(_kAutoEodPrompt) ?? true;
  Future<void> setAutoEodPrompt(bool v) =>
      _prefs.setBool(_kAutoEodPrompt, v);

  /// Wipe session-related keys on logout (keeps baseUrl / retention).
  Future<void> clearSession() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kSessionJson);
  }
}
