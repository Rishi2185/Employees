import 'dart:async';

import 'package:flutter/foundation.dart';

import 'services.dart';

/// Polls `GET /health` so the app can show an online/offline indicator.
class ConnectivityProvider extends ChangeNotifier {
  final Services _services;
  Timer? _timer;
  bool _online = false;
  bool _checking = false;

  ConnectivityProvider(this._services);

  bool get online => _online;
  bool get checking => _checking;

  void start({Duration interval = const Duration(seconds: 20)}) {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  Future<bool> refresh() async {
    if (_checking) return _online;
    _checking = true;
    notifyListeners();
    _online = await _services.health.ping();
    _checking = false;
    notifyListeners();
    return _online;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
