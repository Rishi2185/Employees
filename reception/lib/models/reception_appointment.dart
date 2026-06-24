/// An appointment as seen by reception — a superset of the patient app's model.
///
/// `status` and `paymentMethod` are kept as the backend's INTEGER enum indices
/// (0/1/2) to stay byte-compatible with the patient app. UI labels/colors are
/// derived via StatusUi (guarded against unknown values).
///
/// Knows how to (de)serialize both the API JSON and the local SQLite row.
class ReceptionAppointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorPhotoUrl;
  final String specialtyName;
  final String hospitalName;
  final DateTime dateTime;
  final String slotLabel;
  final int fee;
  final int paymentMethod; // 0 card / 1 upi / 2 wallet
  final int status; // 0 upcoming / 1 completed / 2 cancelled
  final bool reviewed;
  final String? patientName;
  final String? patientPhone;
  final int? patientAge;
  final String? patientGender;
  final int? tokenNumber;
  final bool checkedIn;
  final String? source;
  final String dayKey;
  final String? createdBy;

  const ReceptionAppointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorPhotoUrl,
    required this.specialtyName,
    required this.hospitalName,
    required this.dateTime,
    required this.slotLabel,
    required this.fee,
    required this.paymentMethod,
    required this.status,
    required this.reviewed,
    required this.dayKey,
    this.patientName,
    this.patientPhone,
    this.patientAge,
    this.patientGender,
    this.tokenNumber,
    this.checkedIn = false,
    this.source,
    this.createdBy,
  });

  bool get isUpcoming => status == 0;
  bool get isCompleted => status == 1;
  bool get isCancelled => status == 2;

  // ---- API JSON ----
  factory ReceptionAppointment.fromJson(Map<String, dynamic> json) =>
      ReceptionAppointment(
        id: (json['id'] ?? json['_id']) as String,
        doctorId: json['doctorId'] as String,
        doctorName: (json['doctorName'] ?? '') as String,
        doctorPhotoUrl: (json['doctorPhotoUrl'] ?? '') as String,
        specialtyName: (json['specialtyName'] ?? '') as String,
        hospitalName: (json['hospitalName'] ?? '') as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        slotLabel: (json['slotLabel'] ?? '') as String,
        fee: (json['fee'] ?? 0) as int,
        paymentMethod: (json['paymentMethod'] ?? 1) as int,
        status: (json['status'] ?? 0) as int,
        reviewed: (json['reviewed'] ?? false) as bool,
        patientName: json['patientName'] as String?,
        patientPhone: json['patientPhone'] as String?,
        patientAge: json['patientAge'] as int?,
        patientGender: json['patientGender'] as String?,
        tokenNumber: json['tokenNumber'] as int?,
        checkedIn: (json['checkedIn'] ?? false) as bool,
        source: json['source'] as String?,
        dayKey: (json['dayKey'] ?? '') as String,
        createdBy: json['createdBy'] as String?,
      );

  // ---- Local SQLite row ----
  Map<String, Object?> toDbMap() => {
        'id': id,
        'day_key': dayKey,
        'date_time': dateTime.toIso8601String(),
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'doctor_photo_url': doctorPhotoUrl,
        'specialty_name': specialtyName,
        'hospital_name': hospitalName,
        'slot_label': slotLabel,
        'fee': fee,
        'payment_method': paymentMethod,
        'status': status,
        'reviewed': reviewed ? 1 : 0,
        'patient_name': patientName,
        'patient_phone': patientPhone,
        'patient_age': patientAge,
        'patient_gender': patientGender,
        'token_number': tokenNumber,
        'checked_in': checkedIn ? 1 : 0,
        'source': source,
        'created_by': createdBy,
        'archived_at': DateTime.now().toIso8601String(),
      };

  factory ReceptionAppointment.fromDbMap(Map<String, Object?> r) =>
      ReceptionAppointment(
        id: r['id'] as String,
        dayKey: r['day_key'] as String,
        dateTime: DateTime.parse(r['date_time'] as String),
        doctorId: r['doctor_id'] as String,
        doctorName: (r['doctor_name'] ?? '') as String,
        doctorPhotoUrl: (r['doctor_photo_url'] ?? '') as String,
        specialtyName: (r['specialty_name'] ?? '') as String,
        hospitalName: (r['hospital_name'] ?? '') as String,
        slotLabel: (r['slot_label'] ?? '') as String,
        fee: (r['fee'] ?? 0) as int,
        paymentMethod: (r['payment_method'] ?? 1) as int,
        status: (r['status'] ?? 0) as int,
        reviewed: ((r['reviewed'] ?? 0) as int) == 1,
        patientName: r['patient_name'] as String?,
        patientPhone: r['patient_phone'] as String?,
        patientAge: r['patient_age'] as int?,
        patientGender: r['patient_gender'] as String?,
        tokenNumber: r['token_number'] as int?,
        checkedIn: ((r['checked_in'] ?? 0) as int) == 1,
        source: r['source'] as String?,
        createdBy: r['created_by'] as String?,
      );
}
