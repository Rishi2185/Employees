/// Doctor as served by the backend — a FLAT shape (specialtyId + specialtyName
/// strings), unlike the patient app's nested Specialty object.
class Doctor {
  final String id;
  final String name;
  final String specialtyId;
  final String specialtyName;
  final String qualifications;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final int consultationFee;
  final String about;
  final String photoUrl;
  final String hospitalId;
  final String hospitalName;
  final List<String> languages;
  final int patientsServed;
  final String consultStart;
  final String consultEnd;
  final List<String> availableDays;
  final bool availableToday;
  final bool active;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.specialtyName,
    this.qualifications = '',
    this.experienceYears = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.consultationFee = 0,
    this.about = '',
    this.photoUrl = '',
    this.hospitalId = '',
    this.hospitalName = '',
    this.languages = const [],
    this.patientsServed = 0,
    this.consultStart = '09:00',
    this.consultEnd = '17:00',
    this.availableDays = const [],
    this.availableToday = false,
    this.active = true,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: (json['id'] ?? json['_id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        specialtyId: (json['specialtyId'] ?? '') as String,
        specialtyName: (json['specialtyName'] ?? '') as String,
        qualifications: (json['qualifications'] ?? '') as String,
        experienceYears: (json['experienceYears'] ?? 0) as int,
        rating: ((json['rating'] ?? 0) as num).toDouble(),
        reviewCount: (json['reviewCount'] ?? 0) as int,
        consultationFee: (json['consultationFee'] ?? 0) as int,
        about: (json['about'] ?? '') as String,
        photoUrl: (json['photoUrl'] ?? '') as String,
        hospitalId: (json['hospitalId'] ?? '') as String,
        hospitalName: (json['hospitalName'] ?? '') as String,
        languages:
            (json['languages'] as List?)?.map((e) => e as String).toList() ??
                const [],
        patientsServed: (json['patientsServed'] ?? 0) as int,
        consultStart: (json['consultStart'] ?? '09:00') as String,
        consultEnd: (json['consultEnd'] ?? '17:00') as String,
        availableDays:
            (json['availableDays'] as List?)?.map((e) => e as String).toList() ??
                const [],
        availableToday: (json['availableToday'] ?? false) as bool,
        active: (json['active'] ?? true) as bool,
      );

  /// Admin-only: a shallow copy with selected fields replaced (used for
  /// optimistic in-place updates like toggling `active`).
  Doctor copyWith({
    String? name,
    String? specialtyId,
    String? specialtyName,
    String? qualifications,
    int? experienceYears,
    double? rating,
    int? reviewCount,
    int? consultationFee,
    String? about,
    String? photoUrl,
    String? hospitalId,
    String? hospitalName,
    List<String>? languages,
    int? patientsServed,
    String? consultStart,
    String? consultEnd,
    List<String>? availableDays,
    bool? availableToday,
    bool? active,
  }) =>
      Doctor(
        id: id,
        name: name ?? this.name,
        specialtyId: specialtyId ?? this.specialtyId,
        specialtyName: specialtyName ?? this.specialtyName,
        qualifications: qualifications ?? this.qualifications,
        experienceYears: experienceYears ?? this.experienceYears,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        consultationFee: consultationFee ?? this.consultationFee,
        about: about ?? this.about,
        photoUrl: photoUrl ?? this.photoUrl,
        hospitalId: hospitalId ?? this.hospitalId,
        hospitalName: hospitalName ?? this.hospitalName,
        languages: languages ?? this.languages,
        patientsServed: patientsServed ?? this.patientsServed,
        consultStart: consultStart ?? this.consultStart,
        consultEnd: consultEnd ?? this.consultEnd,
        availableDays: availableDays ?? this.availableDays,
        availableToday: availableToday ?? this.availableToday,
        active: active ?? this.active,
      );
}
