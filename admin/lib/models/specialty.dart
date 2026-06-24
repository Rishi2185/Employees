/// A specialty reference item from `GET /specialties` ({id, name}). Used to
/// populate the doctor edit form's specialty picker; the icon/color mapping
/// stays client-side (the patient app owns that), so admin only needs id+name.
class Specialty {
  final String id;
  final String name;

  const Specialty({required this.id, required this.name});

  factory Specialty.fromJson(Map<String, dynamic> j) => Specialty(
        id: (j['id'] ?? j['_id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
      );
}

/// A hospital reference item from `GET /hospitals` ({id, name, ...}).
class Hospital {
  final String id;
  final String name;

  const Hospital({required this.id, required this.name});

  factory Hospital.fromJson(Map<String, dynamic> j) => Hospital(
        id: (j['id'] ?? j['_id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
      );
}
