import '../models/live_stats.dart';
import 'api_client.dart';

/// Admin stats API. The headline endpoint is `/stats/live` (admin only): a
/// single call returning today's counts, the per-doctor breakdown, and the
/// number of future upcoming appointments.
class StatsApi {
  final ApiClient _client;
  StatsApi(this._client);

  Future<LiveStats> live() async =>
      LiveStats.fromJson(await _client.get('/stats/live') as Map<String, dynamic>);
}
