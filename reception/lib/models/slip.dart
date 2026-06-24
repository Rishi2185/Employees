import 'reception_appointment.dart';

/// The printable appointment-slip payload (from GET /appointments/:id/slip,
/// or built locally from an archived row when offline).
class Slip {
  final String appointmentId;
  final int? tokenNumber;
  final String? patientName;
  final String? patientPhone;
  final String doctorName;
  final String specialtyName;
  final String hospitalName;
  final DateTime dateTime;
  final String slotLabel;
  final int fee;
  final String statusLabel;

  const Slip({
    required this.appointmentId,
    required this.tokenNumber,
    required this.patientName,
    required this.patientPhone,
    required this.doctorName,
    required this.specialtyName,
    required this.hospitalName,
    required this.dateTime,
    required this.slotLabel,
    required this.fee,
    required this.statusLabel,
  });

  factory Slip.fromJson(Map<String, dynamic> j) => Slip(
        appointmentId: j['appointmentId'] as String,
        tokenNumber: j['tokenNumber'] as int?,
        patientName: j['patientName'] as String?,
        patientPhone: j['patientPhone'] as String?,
        doctorName: (j['doctorName'] ?? '') as String,
        specialtyName: (j['specialtyName'] ?? '') as String,
        hospitalName: (j['hospitalName'] ?? '') as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        slotLabel: (j['slotLabel'] ?? '') as String,
        fee: (j['fee'] ?? 0) as int,
        statusLabel: (j['statusLabel'] ?? '') as String,
      );

  /// Build a slip locally from an archived appointment (offline reprint).
  factory Slip.fromAppointment(ReceptionAppointment a, {String statusLabel = ''}) =>
      Slip(
        appointmentId: a.id,
        tokenNumber: a.tokenNumber,
        patientName: a.patientName,
        patientPhone: a.patientPhone,
        doctorName: a.doctorName,
        specialtyName: a.specialtyName,
        hospitalName: a.hospitalName,
        dateTime: a.dateTime,
        slotLabel: a.slotLabel,
        fee: a.fee,
        statusLabel: statusLabel,
      );
}
