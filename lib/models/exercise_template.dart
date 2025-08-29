/// Gyakorlatsablon - egy gyakorlat alapadatait és utolsó értékeit tárolja
class ExerciseTemplate {
  final String id; // Egyedi azonosító
  final String name; // Gyakorlat neve (pl. "Fekvőtámasz", "Húzódzkodás")
  final String tip; // Opcionális tipp vagy megjegyzés
  final double? lastWeight; // Utolsó alkalommal használt súly
  final int? lastReps; // Utolsó alkalommal használt ismétlésszám
  final DateTime? lastPerformed; // Mikor csinálta utoljára
  final double? maxWeight; // Eddigi maximum súly (PR - Personal Record)
  final int? maxReps; // Eddigi maximum ismétlésszám egyazon súllyal

  ExerciseTemplate({
    required this.id,
    required this.name,
    this.tip = '',
    this.lastWeight,
    this.lastReps,
    this.lastPerformed,
    this.maxWeight,
    this.maxReps,
  });

  /// JSON-ba konvertálás
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tip': tip,
    'lastWeight': lastWeight,
    'lastReps': lastReps,
    'lastPerformed': lastPerformed?.toIso8601String(),
    'maxWeight': maxWeight,
    'maxReps': maxReps,
  };

  /// JSON-ból objektum létrehozása
  static ExerciseTemplate fromJson(Map<String, dynamic> json) => ExerciseTemplate(
    id: json['id'],
    name: json['name'],
    tip: json['tip'] ?? '',
    lastWeight: json['lastWeight']?.toDouble(),
    lastReps: json['lastReps'],
    lastPerformed: json['lastPerformed'] != null 
        ? DateTime.parse(json['lastPerformed']) 
        : null,
    maxWeight: json['maxWeight']?.toDouble(),
    maxReps: json['maxReps'],
  );

  /// Sablon másolása frissített értékekkel
  ExerciseTemplate copyWith({
    String? id,
    String? name,
    String? tip,
    double? lastWeight,
    int? lastReps,
    DateTime? lastPerformed,
    double? maxWeight,
    int? maxReps,
  }) {
    return ExerciseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      tip: tip ?? this.tip,
      lastWeight: lastWeight ?? this.lastWeight,
      lastReps: lastReps ?? this.lastReps,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      maxWeight: maxWeight ?? this.maxWeight,
      maxReps: maxReps ?? this.maxReps,
    );
  }

  /// Frissítés új szett adatokkal (súly és ismétlés alapján)
  ExerciseTemplate updateWithSet({
    required double weight,
    required int reps,
    DateTime? performedAt,
  }) {
    final now = performedAt ?? DateTime.now();
    
    // Új maximum súly ellenőrzése
    final newMaxWeight = maxWeight == null || weight > maxWeight! 
        ? weight 
        : maxWeight!;
    
    // Új maximum ismétlésszám ellenőrzése (ugyanazon súllyal)
    final newMaxReps = (maxWeight == null || weight >= maxWeight!) && 
                       (maxReps == null || reps > maxReps!)
        ? reps 
        : maxReps;

    return copyWith(
      lastWeight: weight,
      lastReps: reps,
      lastPerformed: now,
      maxWeight: newMaxWeight,
      maxReps: newMaxReps,
    );
  }

  /// Van-e korábbi adat
  bool get hasHistory => lastWeight != null && lastReps != null;

  /// Utolsó teljesítmény szövegesen
  String get lastPerformanceText {
    if (!hasHistory) return 'Még nem volt edzés';
    return '${lastWeight!.toStringAsFixed(1)} kg × ${lastReps!} db';
  }

  /// Maximum teljesítmény szövegesen
  String get maxPerformanceText {
    if (maxWeight == null) return 'Nincs még rekord';
    return 'PR: ${maxWeight!.toStringAsFixed(1)} kg × ${maxReps ?? 0} db';
  }

  /// Mennyi ideje csinálta utoljára (napokban)
  int? get daysSinceLastPerformed {
    if (lastPerformed == null) return null;
    return DateTime.now().difference(lastPerformed!).inDays;
  }
}