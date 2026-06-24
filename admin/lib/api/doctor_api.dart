import '../models/doctor.dart';
import '../models/doctor_input.dart';
import 'api_client.dart';

/// Doctor roster API for the admin app. Unlike reception (read-only), admin can
/// create/update/soft-delete doctors — changes write to the cloud Doctors store
/// and are immediately reflected in the patient app.
class DoctorApi {
  final ApiClient _client;
  DoctorApi(this._client);

  /// List doctors. [includeInactive] surfaces soft-deleted doctors so the admin
  /// can reactivate them (the patient app never sees inactive ones).
  Future<Paged<Doctor>> list({
    String? q,
    String? specialtyId,
    bool? availableToday,
    bool includeInactive = false,
    String? sort,
    int page = 1,
    int limit = 100,
  }) {
    return _client.getPaged<Doctor>('/doctors', Doctor.fromJson, query: {
      'q': q,
      'specialtyId': specialtyId,
      'availableToday': availableToday,
      'includeInactive': includeInactive ? 'true' : null,
      'sort': sort,
      'page': page,
      'limit': limit,
    });
  }

  Future<Doctor> getById(String id) async =>
      Doctor.fromJson(await _client.get('/doctors/$id') as Map<String, dynamic>);

  /// Create a new doctor (admin). Returns the created record.
  Future<Doctor> create(DoctorInput input) async {
    final data =
        await _client.post('/doctors', body: input.toJson()) as Map<String, dynamic>;
    return Doctor.fromJson(data);
  }

  /// Update an existing doctor (admin). Returns the updated record.
  Future<Doctor> update(String id, DoctorInput input) async {
    final data = await _client.patch('/doctors/$id', body: input.toJson())
        as Map<String, dynamic>;
    return Doctor.fromJson(data);
  }

  /// Soft-delete (deactivate) a doctor. Returns the new `active` flag.
  Future<bool> deactivate(String id) async {
    final data = await _client.delete('/doctors/$id') as Map<String, dynamic>;
    return (data['active'] ?? false) as bool;
  }

  /// Reactivate a previously soft-deleted doctor via a PATCH.
  Future<Doctor> reactivate(String id) async {
    final data = await _client
        .patch('/doctors/$id', body: {'active': true}) as Map<String, dynamic>;
    return Doctor.fromJson(data);
  }
}
