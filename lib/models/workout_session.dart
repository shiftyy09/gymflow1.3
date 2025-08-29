import 'set_data.dart';

/// Edzésnaplózás - egy konkrét edzésalkalom adatait tárolja
class WorkoutSession {
  final String id; // Egyedi azonosító
  final String templateId; // Melyik sablonból indult
  final String templateName; // Sablon neve (gyorsabb eléréshez)
  final DateTime startedAt; // Edzés kezdete
  final DateTime? completedAt; // Edzés befejezése
  final List<ExerciseSession> exerciseSessions; // Elvégzett gyakorlatok
  final bool isCompleted; // Befejezett-e az edzés
  final String? notes; // Opcionális megjegyzések

  WorkoutSession({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.startedAt,
    this.completedAt,
    required this.exerciseSessions,
    this.isCompleted = false,
    this.notes,
  });

  /// JSON-ba konvertálás
  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'templateName': templateName,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'exerciseSessions': exerciseSessions.map((e) => e.toJson()).toList(),
    'isCompleted': isCompleted,
    'notes': notes,
  };

  /// JSON-ból objektum létrehozása
  static WorkoutSession fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'],
    templateId: json['templateId'],
    templateName: json['templateName'],
    startedAt: DateTime.parse(json['startedAt']),
    completedAt: json['completedAt'] != null 
        ? DateTime.parse(json['completedAt']) 
        : null,
    exerciseSessions: (json['exerciseSessions'] as List)
        .map((e) => ExerciseSession.fromJson(e))
        .toList(),
    isCompleted: json['isCompleted'] ?? false,
    notes: json['notes'],
  );

  /// Session másolása frissített értékekkel
  WorkoutSession copyWith({
    String? id,
    String? templateId,
    String? templateName,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ExerciseSession>? exerciseSessions,
    bool? isCompleted,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      exerciseSessions: exerciseSessions ?? this.exerciseSessions,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  /// Edzés befejezése
  WorkoutSession complete({String? notes}) {
    return copyWith(
      completedAt: DateTime.now(),
      isCompleted: true,
      notes: notes,
    );
  }

  /// Edzés időtartama (percekben)
  int? get durationMinutes {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt).inMinutes;
  }

  /// Összesen hány szett lett elvégezve
  int get totalSets => exerciseSessions
      .map((e) => e.sets.length)
      .fold(0, (sum, count) => sum + count);

  /// Van-e legalább egy elvégzett szett
  bool get hasCompletedSets => totalSets > 0;

  /// Elvégzett gyakorlatok száma (amelyeknek van legalább egy szettje)
  int get completedExercisesCount => exerciseSessions
      .where((e) => e.sets.isNotEmpty)
      .length;
}

/// Egy gyakorlat egy edzésen belüli adatai
class ExerciseSession {
  final String exerciseTemplateId; // Sablon azonosítója
  final String exerciseName; // Gyakorlat neve
  final List<SetData> sets; // Elvégzett szettek
  final String? notes; // Gyakorlat-specifikus megjegyzések

  ExerciseSession({
    required this.exerciseTemplateId,
    required this.exerciseName,
    required this.sets,
    this.notes,
  });

  /// JSON-ba konvertálás
  Map<String, dynamic> toJson() => {
    'exerciseTemplateId': exerciseTemplateId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
  };

  /// JSON-ból objektum létrehozása
  static ExerciseSession fromJson(Map<String, dynamic> json) => ExerciseSession(
    exerciseTemplateId: json['exerciseTemplateId'],
    exerciseName: json['exerciseName'],
    sets: (json['sets'] as List)
        .map((s) => SetData.fromJson(s))
        .toList(),
    notes: json['notes'],
  );

  /// Session másolása frissített értékekkel
  ExerciseSession copyWith({
    String? exerciseTemplateId,
    String? exerciseName,
    List<SetData>? sets,
    String? notes,
  }) {
    return ExerciseSession(
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  /// Szett hozzáadása
  ExerciseSession addSet(SetData setData) {
    return copyWith(sets: [...sets, setData]);
  }

  /// Szett eltávolítása
  ExerciseSession removeSet(int index) {
    if (index < 0 || index >= sets.length) return this;
    final newSets = List<SetData>.from(sets);
    newSets.removeAt(index);
    return copyWith(sets: newSets);
  }

  /// Maximum súly ebben a sessionben
  double? get maxWeightInSession {
    if (sets.isEmpty) return null;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  /// Összesen hány ismétlés
  int get totalReps => sets.map((s) => s.reps).fold(0, (sum, reps) => sum + reps);
}