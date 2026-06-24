import '../models/specialty.dart';
import 'api_client.dart';

/// Reference data (specialties + hospitals) for the doctor edit form's pickers.
class MetaApi {
  final ApiClient _client;
  MetaApi(this._client);

  Future<List<Specialty>> specialties() async {
    final data = await _client.get('/specialties') as Map<String, dynamic>;
    return ((data['data'] ?? const []) as List)
        .map((e) => Specialty.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Hospital>> hospitals() async {
    final data = await _client.get('/hospitals') as Map<String, dynamic>;
    return ((data['data'] ?? const []) as List)
        .map((e) => Hospital.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
