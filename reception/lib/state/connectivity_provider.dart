import 'dart:async';

import 'package:flutter/foundation.dart';

import 'services.dart';

/// Polls the backend's `/health` so the rest of the app can show an online /
/// offline badge and gate cloud-only actions (the EOD purge needs the cloud;
/// archive reads can fall back to the local DB).
class ConnectivityProvider extends ChangeNotifier {
  final Services _services;
  Timer? _timer;
  bool _online = false;
  bool _checking = false;
  DateTime? _lastChecked;

  ConnectivityProvider(this._services);

  bool get online => _online;
  bool get checking => _checking;
  DateTime? get lastChecked => _lastChecked;

  /// Begin periodic health checks (default every 20s) and run one immediately.
  void start({Duration interval = const Duration(seconds: 20)}) {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  Future<bool> refresh() async {
    if (_checking) return _online;
    _checking = true;
    notifyListeners();
    final result = await _services.health.ping();
    _online = result;
    _lastChecked = DateTime.now();
    _checking = false;
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
