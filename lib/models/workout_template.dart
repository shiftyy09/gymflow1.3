import 'exercise_template.dart';

/// Edzéssablon – egy ismételhető edzéstípust reprezentál
/// (pl. "MELL", "HÁT", "LÁB")
class WorkoutTemplate {
  final String id; // Egyedi azonosító
  final String name; // "MELL", "HÁT", "LÁB"
  final String? description; // Opcionális leírás
  final List<ExerciseTemplate> exerciseTemplates;
  final DateTime createdAt;
  final DateTime lastUsed;

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.exerciseTemplates,
    required this.createdAt,
    required this.lastUsed,
  });

  /// JSON-ba konvertálás
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'exerciseTemplates':
    exerciseTemplates.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastUsed': lastUsed.toIso8601String(),
  };

  /// JSON-ból objektum létrehozása
  static WorkoutTemplate fromJson(Map<String, dynamic> json) =>
      WorkoutTemplate(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        exerciseTemplates: (json['exerciseTemplates'] as List)
            .map((e) => ExerciseTemplate.fromJson(e))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        lastUsed: DateTime.parse(json['lastUsed']),
      );

  /// Sablon másolása frissített lastUsed dátummal
  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<ExerciseTemplate>? exerciseTemplates,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exerciseTemplates: exerciseTemplates ?? this.exerciseTemplates,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Ellenőrzés: van-e legalább egy gyakorlat
  bool get isValid => exerciseTemplates.isNotEmpty;

  /// Utoljára használt súlyok listája (statisztikákhoz)
  List<double> get lastWeights => exerciseTemplates
      .where((e) => e.lastWeight != null)
      .map((e) => e.lastWeight!)
      .toList();
}
