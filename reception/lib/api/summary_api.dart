import '../models/daily_summary.dart';
import 'api_client.dart';

class SummaryApi {
  final ApiClient _client;
  SummaryApi(this._client);

  /// End-of-day summary write (server computes counts; idempotent).
  Future<DailySummary> write(String dayKey) async {
    final data = await _client.post('/summaries', body: {'dayKey': dayKey})
        as Map<String, dynamic>;
    return DailySummary.fromJson(data);
  }

  Future<List<DailySummary>> range({String? from, String? to, String? doctorId}) async {
    final data = await _client.get('/summaries',
        query: {'from': from, 'to': to, 'doctorId': doctorId}) as Map<String, dynamic>;
    return ((data['data'] ?? const []) as List)
        .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DailySummary?> getByDay(String dayKey) async {
    final data = await _client.get('/summaries/$dayKey');
    if (data is! Map<String, dynamic>) return null;
    return DailySummary.fromJson(data);
  }
}
