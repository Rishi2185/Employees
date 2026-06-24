import '../models/daily_summary.dart';
import '../models/doctor_trend.dart';
import 'api_client.dart';

/// Historical-trends API backed by the cloud Daily Summaries store (counts only,
/// no PII). The same endpoint returns two shapes:
///  - without `doctorId`: full per-day [DailySummary] documents (overall trend),
///  - with `doctorId`: a flattened [DoctorTrendPoint] per day for that doctor.
class SummaryApi {
  final ApiClient _client;
  SummaryApi(this._client);

  /// Overall per-day summaries across a date range (inclusive dayKeys).
  Future<List<DailySummary>> overall({String? from, String? to}) async {
    final data = await _client.get('/summaries', query: {'from': from, 'to': to})
        as Map<String, dynamic>;
    return ((data['data'] ?? const []) as List)
        .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// One doctor's per-day numbers across a date range.
  Future<List<DoctorTrendPoint>> forDoctor(
    String doctorId, {
    String? from,
    String? to,
  }) async {
    final data = await _client.get('/summaries',
            query: {'from': from, 'to': to, 'doctorId': doctorId})
        as Map<String, dynamic>;
    return ((data['data'] ?? const []) as List)
        .map((e) => DoctorTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DailySummary?> getByDay(String dayKey) async {
    final data = await _client.get('/summaries/$dayKey');
    if (data is! Map<String, dynamic>) return null;
    return DailySummary.fromJson(data);
  }
}
