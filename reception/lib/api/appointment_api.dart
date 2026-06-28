import '../models/reception_appointment.dart';
import '../models/slip.dart';
import 'api_client.dart';

class AppointmentApi {
  final ApiClient _client;
  AppointmentApi(this._client);

  Future<Paged<ReceptionAppointment>> list({
    String? date,
    String? from,
    String? to,
    String? doctorId,
    int? status,
    String? q,
    bool? checkedIn,
    int page = 1,
    int limit = 50,
  }) {
    return _client.getPaged<ReceptionAppointment>(
      '/appointments',
      ReceptionAppointment.fromJson,
      query: {
        'date': date,
        'from': from,
        'to': to,
        'doctorId': doctorId,
        'status': status,
        'q': q,
        'checkedIn': checkedIn,
        'page': page,
        'limit': limit,
      },
    );
  }

  Future<ReceptionAppointment> getById(String id) async =>
      ReceptionAppointment.fromJson(
          await _client.get('/appointments/$id') as Map<String, dynamic>);

  /// Reception walk-in / desk booking. Requires patientName + patientPhone.
  Future<ReceptionAppointment> createWalkIn({
    required String doctorId,
    required DateTime dateTime,
    required String slotLabel,
    required String patientName,
    required String patientPhone,
    int? patientAge,
    String? patientGender,
    int? paymentMethod,
    int? fee,
    int? tokenNumber,
  }) async {
    final data = await _client.post('/appointments', body: {
      'doctorId': doctorId,
      'dateTime': dateTime.toIso8601String(),
      'slotLabel': slotLabel,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientAge': ?patientAge,
      'patientGender': ?patientGender,
      'paymentMethod': ?paymentMethod,
      'fee': ?fee,
      'tokenNumber': ?tokenNumber,
    }) as Map<String, dynamic>;
    return ReceptionAppointment.fromJson(data);
  }

  Future<ReceptionAppointment> patch(String id, Map<String, dynamic> changes) async =>
      ReceptionAppointment.fromJson(
          await _client.patch('/appointments/$id', body: changes)
              as Map<String, dynamic>);

  Future<void> deleteOne(String id) => _client.delete('/appointments/$id');

  Future<Slip> slip(String id) async =>
      Slip.fromJson(await _client.get('/appointments/$id/slip')
          as Map<String, dynamic>);

  /// End-of-day purge of a past day's full records (gated server-side).
  Future<int> purgeDay(String dayKey) async {
    final data = await _client.delete('/appointments',
        query: {'date': dayKey, 'confirm': dayKey}) as Map<String, dynamic>;
    return (data['deleted'] ?? 0) as int;
  }
}
