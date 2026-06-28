import 'package:shared_preferences/shared_preferences.dart';

/// Persistent admin settings, backed by `shared_preferences`: the backend URL
/// and the authenticated session (so the admin stays signed in across launches).
class SettingsStore {
  final SharedPreferences _prefs;
  SettingsStore(this._prefs);

  static Future<SettingsStore> load() async =>
      SettingsStore(await SharedPreferences.getInstance());

  static const _kBaseUrl = 'baseUrl';
  static const _kToken = 'authToken';
  static const _kSessionJson = 'authSession';

  static const String defaultBaseUrl = 'http://3.110.77.2:4000/api';

  /// Backend base URL. Defaults to the deployed AWS server. For local development
  /// against a backend on the dev PC, use `http://10.0.2.2:4000/api` (the Android
  /// emulator's alias for the host's `localhost`).
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

  String? get sessionJson => _prefs.getString(_kSessionJson);
  Future<void> setSessionJson(String? v) async {
    if (v == null) {
      await _prefs.remove(_kSessionJson);
    } else {
      await _prefs.setString(_kSessionJson, v);
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kSessionJson);
  }
}
