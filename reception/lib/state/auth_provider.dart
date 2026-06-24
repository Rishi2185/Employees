import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/auth_session.dart';
import 'services.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Owns the reception sign-in lifecycle: restores a saved session on boot,
/// logs in/out, keeps the [ApiClient] token in sync, and reacts to 401s.
class AuthProvider extends ChangeNotifier {
  final Services _services;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  bool _busy = false;
  String? _error;

  AuthProvider(this._services) {
    // A 401 from any request forces a sign-out so the UI returns to login.
    _services.api.onUnauthorized = _onUnauthorized;
    _restore();
  }

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  bool get busy => _busy;
  String? get error => _error;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get isReception => _session?.role == 'reception';
  bool get isAdmin => _session?.role == 'admin';
  String get displayName => _session?.displayName ?? '';

  void _restore() {
    final raw = _services.settings.sessionJson;
    if (raw == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      final session = AuthSession.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      _applySession(session);
    } catch (_) {
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _services.auth.login(username.trim(), password);
      await _services.settings.setToken(session.token);
      await _services.settings.setSessionJson(jsonEncode(session.toJson()));
      _applySession(session);
      return true;
    } on ApiException catch (e) {
      _error = e.isNetwork
          ? e.message
          : (e.status == 401 ? 'Invalid username or password.' : e.message);
      _status = AuthStatus.signedOut;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _applySession(AuthSession session) {
    _session = session;
    _services.api.token = session.token;
    _status = AuthStatus.signedIn;
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _services.settings.clearSession();
    _services.api.token = null;
    _session = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  void _onUnauthorized() {
    // Don't await — fire-and-forget so the failing request unwinds cleanly.
    if (_status == AuthStatus.signedIn) {
      _error = 'Your session expired. Please sign in again.';
      logout();
    }
  }

  @override
  void dispose() {
    _services.api.onUnauthorized = null;
    super.dispose();
  }
}
