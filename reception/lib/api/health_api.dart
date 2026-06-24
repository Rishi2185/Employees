import 'api_client.dart';

/// Liveness check against the backend. Used by the connectivity provider to
/// decide online/offline and to gate the end-of-day job (which needs the cloud).
class HealthApi {
  final ApiClient _client;
  HealthApi(this._client);

  /// Returns true if `GET /health` responds OK. Never throws — a network error
  /// simply means "offline".
  Future<bool> ping() async {
    try {
      final data = await _client.get('/health');
      if (data is Map) {
        final status = (data['status'] ?? data['ok']);
        if (status is bool) return status;
        return status == 'ok' || status == 'up' || status == true;
      }
      return true; // 2xx with any body counts as reachable
    } catch (_) {
      return false;
    }
  }
}
