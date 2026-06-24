import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/auth_session.dart';
import 'services.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Admin sign-in lifecycle. **Admin-only**: a successful login with a non-admin
/// role (e.g. reception) is rejected here — the management dashboard is gated to
/// administrators. Restores a saved admin session on boot and reacts to 401s.
class AuthProvider extends ChangeNotifier {
  final Services _services;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  bool _busy = false;
  String? _error;

  AuthProvider(this._services) {
    _services.api.onUnauthorized = _onUnauthorized;
    _restore();
  }

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  bool get busy => _busy;
  String? get error => _error;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  String get displayName => _session?.displayName ?? '';

  void _restore() {
    final raw = _services.settings.sessionJson;
    if (raw == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      final session =
          AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // Only honour a stored session if it's an admin one.
      if (session.role == 'admin') {
        _applySession(session);
      } else {
        _services.settings.clearSession();
        _status = AuthStatus.signedOut;
        notifyListeners();
      }
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

      // Gate: administrators only.
      if (session.role != 'admin') {
        _error = 'This app is for administrators only.';
        _status = AuthStatus.signedOut;
        return false;
      }

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
