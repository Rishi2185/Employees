import '../models/availability.dart';
import '../models/doctor.dart';
import 'api_client.dart';

class DoctorApi {
  final ApiClient _client;
  DoctorApi(this._client);

  Future<Paged<Doctor>> list({
    String? q,
    String? specialtyId,
    bool? availableToday,
    double? minRating,
    String? sort,
    int page = 1,
    int limit = 50,
  }) {
    return _client.getPaged<Doctor>('/doctors', Doctor.fromJson, query: {
      'q': q,
      'specialtyId': specialtyId,
      'availableToday': availableToday,
      'minRating': minRating,
      'sort': sort,
      'page': page,
      'limit': limit,
    });
  }

  Future<Doctor> getById(String id) async =>
      Doctor.fromJson(await _client.get('/doctors/$id') as Map<String, dynamic>);

  Future<Availability> availability(String id, String dayKey) async {
    final data = await _client
        .get('/doctors/$id/availability', query: {'date': dayKey}) as Map<String, dynamic>;
    return Availability.fromJson(data);
  }
}
