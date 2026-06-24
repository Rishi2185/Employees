import 'doctor.dart';

/// The editable doctor payload for `POST /doctors` (create) and
/// `PATCH /doctors/:id` (update). The backend's update schema accepts the same
/// fields as create (minus `_id`), so one `toJson()` serves both — the admin
/// edits the full form and we send the whole set.
///
/// `name`, `specialtyId`, and `specialtyName` are required by the server;
/// everything else has a sensible default matching the Doctor model.
class DoctorInput {
  String name;
  String specialtyId;
  String specialtyName;
  String qualifications;
  int experienceYears;
  double rating;
  int reviewCount;
  int consultationFee;
  String about;
  String photoUrl;
  String hospitalId;
  String hospitalName;
  List<String> languages;
  int patientsServed;
  String consultStart;
  String consultEnd;
  List<String> availableDays;
  bool availableToday;
  bool active;

  DoctorInput({
    this.name = '',
    this.specialtyId = '',
    this.specialtyName = '',
    this.qualifications = '',
    this.experienceYears = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.consultationFee = 0,
    this.about = '',
    this.photoUrl = '',
    this.hospitalId = '',
    this.hospitalName = '',
    List<String>? languages,
    this.patientsServed = 0,
    this.consultStart = '09:00',
    this.consultEnd = '17:00',
    List<String>? availableDays,
    this.availableToday = false,
    this.active = true,
  })  : languages = languages ?? [],
        availableDays = availableDays ?? [];

  /// Seed the form from an existing doctor (edit flow).
  factory DoctorInput.fromDoctor(Doctor d) => DoctorInput(
        name: d.name,
        specialtyId: d.specialtyId,
        specialtyName: d.specialtyName,
        qualifications: d.qualifications,
        experienceYears: d.experienceYears,
        rating: d.rating,
        reviewCount: d.reviewCount,
        consultationFee: d.consultationFee,
        about: d.about,
        photoUrl: d.photoUrl,
        hospitalId: d.hospitalId,
        hospitalName: d.hospitalName,
        languages: List<String>.from(d.languages),
        patientsServed: d.patientsServed,
        consultStart: d.consultStart,
        consultEnd: d.consultEnd,
        availableDays: List<String>.from(d.availableDays),
        availableToday: d.availableToday,
        active: d.active,
      );

  /// Client-side validation mirroring the server's required fields. Returns an
  /// error message, or null if valid.
  String? validate() {
    if (name.trim().isEmpty) return 'Doctor name is required.';
    if (specialtyId.trim().isEmpty || specialtyName.trim().isEmpty) {
      return 'Please choose a specialty.';
    }
    if (consultationFee < 0) return 'Fee cannot be negative.';
    if (rating < 0 || rating > 5) return 'Rating must be between 0 and 5.';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'specialtyId': specialtyId.trim(),
        'specialtyName': specialtyName.trim(),
        'qualifications': qualifications.trim(),
        'experienceYears': experienceYears,
        'rating': rating,
        'reviewCount': reviewCount,
        'consultationFee': consultationFee,
        'about': about.trim(),
        'photoUrl': photoUrl.trim(),
        'hospitalId': hospitalId.trim(),
        'hospitalName': hospitalName.trim(),
        'languages': languages,
        'patientsServed': patientsServed,
        'consultStart': consultStart,
        'consultEnd': consultEnd,
        'availableDays': availableDays,
        'availableToday': availableToday,
        'active': active,
      };
}
