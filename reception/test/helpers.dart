import 'package:aarvy_reception/models/reception_appointment.dart';

/// Build a ReceptionAppointment with sensible defaults for tests.
ReceptionAppointment appt({
  required String id,
  required String dayKey,
  String doctorId = 'd1',
  String doctorName = 'Dr. Asha Rao',
  int status = 1,
  int fee = 500,
  String? patientName = 'Test Patient',
  String? patientPhone = '9990001112',
  int? tokenNumber,
  String? source,
  DateTime? dateTime,
}) {
  return ReceptionAppointment(
    id: id,
    doctorId: doctorId,
    doctorName: doctorName,
    doctorPhotoUrl: '',
    specialtyName: 'Cardiology',
    hospitalName: 'Aarvy Hospital',
    dateTime: dateTime ?? DateTime.parse('${dayKey}T10:30:00'),
    slotLabel: '10:30 AM',
    fee: fee,
    paymentMethod: 1,
    status: status,
    reviewed: false,
    dayKey: dayKey,
    patientName: patientName,
    patientPhone: patientPhone,
    tokenNumber: tokenNumber,
    source: source,
  );
}
