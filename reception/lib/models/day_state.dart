/// The end-of-day progress for a single clinic day, persisted locally so the
/// archive → summarize → purge job is **resumable and idempotent** across app
/// restarts and crashes.
///
/// The stages form a strict forward ladder:
///   pending → archived → summarized → purged (done)
/// Each stage is only entered after the previous one is durably recorded, so a
/// crash mid-job resumes from the last completed stage rather than re-running
/// destructive steps.
enum EodStage {
  pending,
  archived,
  summarized,
  purged;

  static EodStage fromName(String? s) {
    switch (s) {
      case 'archived':
        return EodStage.archived;
      case 'summarized':
        return EodStage.summarized;
      case 'purged':
        return EodStage.purged;
      default:
        return EodStage.pending;
    }
  }

  /// Has this day fully completed the EOD job?
  bool get isDone => this == EodStage.purged;

  /// Ordering helper for "have we at least reached stage X".
  bool reached(EodStage other) => index >= other.index;
}

class DayState {
  final String dayKey;
  final EodStage stage;
  final int archivedCount;
  final int purgedCount;
  final DateTime? archivedAt;
  final DateTime? summarizedAt;
  final DateTime? purgedAt;
  final String? lastError;
  final DateTime updatedAt;

  const DayState({
    required this.dayKey,
    required this.stage,
    this.archivedCount = 0,
    this.purgedCount = 0,
    this.archivedAt,
    this.summarizedAt,
    this.purgedAt,
    this.lastError,
    required this.updatedAt,
  });

  bool get isDone => stage.isDone;

  DayState copyWith({
    EodStage? stage,
    int? archivedCount,
    int? purgedCount,
    DateTime? archivedAt,
    DateTime? summarizedAt,
    DateTime? purgedAt,
    String? lastError,
    bool clearError = false,
    DateTime? updatedAt,
  }) =>
      DayState(
        dayKey: dayKey,
        stage: stage ?? this.stage,
        archivedCount: archivedCount ?? this.archivedCount,
        purgedCount: purgedCount ?? this.purgedCount,
        archivedAt: archivedAt ?? this.archivedAt,
        summarizedAt: summarizedAt ?? this.summarizedAt,
        purgedAt: purgedAt ?? this.purgedAt,
        lastError: clearError ? null : (lastError ?? this.lastError),
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDbMap() => {
        'day_key': dayKey,
        'stage': stage.name,
        'archived_count': archivedCount,
        'purged_count': purgedCount,
        'archived_at': archivedAt?.toIso8601String(),
        'summarized_at': summarizedAt?.toIso8601String(),
        'purged_at': purgedAt?.toIso8601String(),
        'last_error': lastError,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DayState.fromDbMap(Map<String, Object?> r) => DayState(
        dayKey: r['day_key'] as String,
        stage: EodStage.fromName(r['stage'] as String?),
        archivedCount: (r['archived_count'] ?? 0) as int,
        purgedCount: (r['purged_count'] ?? 0) as int,
        archivedAt: _parse(r['archived_at']),
        summarizedAt: _parse(r['summarized_at']),
        purgedAt: _parse(r['purged_at']),
        lastError: r['last_error'] as String?,
        updatedAt: _parse(r['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  static DateTime? _parse(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}
