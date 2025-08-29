import 'dart:convert';

class SetData {
  double weight;
  int reps;
  SetData({required this.weight, required this.reps});
  Map<String, dynamic> toJson() => {
    'weight': weight,
    'reps': reps,
  };
  static SetData fromJson(Map<String, dynamic> json) =>
      SetData(weight: (json['weight']).toDouble(), reps: json['reps']);
}

class Exercise {
  String name;
  List<SetData> sets;
  String tip;
  Exercise({required this.name, List<SetData>? sets, this.tip = ''})
      : sets = sets ?? [];
  double? get previousWeight => sets.isNotEmpty ? sets.last.weight : null;
  Map<String, dynamic> toJson() => {
    'name': name,
    'tip': tip,
    'sets': sets.map((e) => e.toJson()).toList(),
  };
  static Exercise fromJson(Map<String, dynamic> json) =>
      Exercise(
          name: json['name'],
          tip: json['tip'],
          sets: (json['sets'] as List)
              .map((e) => SetData.fromJson(e))
              .toList(),
      );
}

class WorkoutDay {
  String name;
  DateTime date;
  List<Exercise> exercises;
  WorkoutDay({required this.name, required this.date, required this.exercises});
  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
  static WorkoutDay fromJson(Map<String, dynamic> json) =>
      WorkoutDay(
          name: json['name'],
          date: DateTime.parse(json['date']),
          exercises: (json['exercises'] as List)
              .map((e) => Exercise.fromJson(e))
              .toList(),
      );
}
