import '../models/stats.dart';
import 'api_client.dart';

class StatsApi {
  final ApiClient _client;
  StatsApi(this._client);

  Future<TodayStats> today() async =>
      TodayStats.fromJson(await _client.get('/stats/today') as Map<String, dynamic>);

  Future<Overview> overview() async =>
      Overview.fromJson(await _client.get('/stats/overview') as Map<String, dynamic>);

  Future<List<DoctorStat>> doctors({String? date}) async {
    final data = await _client.get('/stats/doctors', query: {'date': date})
        as Map<String, dynamic>;
    return ((data['perDoctor'] ?? const []) as List)
        .map((e) => DoctorStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
