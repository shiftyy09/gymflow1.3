import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/exercise_template.dart';

/// Edzéssablon és edzésnaplók kezelése
class WorkoutService {
  static const String _templatesKey = 'workout_templates';
  static const String _sessionsKey = 'workout_sessions';

  /// Összes sablon betöltése
  Future<List<WorkoutTemplate>> loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_templatesKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((json) => WorkoutTemplate.fromJson(json)).toList();
    } catch (e) {
      print('Hiba a sablonok betöltésekor: $e');
      return [];
    }
  }

  /// Sablonok mentése
  Future<void> saveTemplates(List<WorkoutTemplate> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(templates.map((t) => t.toJson()).toList());
      await prefs.setString(_templatesKey, encoded);
    } catch (e) {
      print('Hiba a sablonok mentésekor: $e');
    }
  }

  /// Új sablon létrehozása
  Future<WorkoutTemplate> createTemplate({
    required String name,
    String? description,
    List<String>? exerciseNames,
  }) async {
    final now = DateTime.now();
    final templateId = 'template_${now.millisecondsSinceEpoch}';
    final exerciseTemplates = exerciseNames
        ?.map((name) => ExerciseTemplate(
      id: 'exercise_${now.millisecondsSinceEpoch}_${exerciseNames.indexOf(name)}',
      name: name,
    ))
        .toList() ??
        <ExerciseTemplate>[];
    final template = WorkoutTemplate(
      id: templateId,
      name: name,
      description: description,
      exerciseTemplates: exerciseTemplates,
      createdAt: now,
      lastUsed: now,
    );
    final templates = await loadTemplates();
    templates.insert(0, template);
    await saveTemplates(templates);
    return template;
  }

  /// Egyéni edzésnap sablon mentése
  Future<void> createCustomDay({
    required String dayName,
    required List<String> exercises,
  }) async {
    final now = DateTime.now();
    // Új egyéni sablon ExerciseTemplate listává alakítása
    final exerciseTemplates = exercises.map((name) {
      return ExerciseTemplate(
        id: 'custom_${now.millisecondsSinceEpoch}_${exercises.indexOf(name)}',
        name: name,
      );
    }).toList();
    // Új sablon létrehozása WorkoutTemplate-ként
    final template = WorkoutTemplate(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: dayName,
      description: null,
      exerciseTemplates: exerciseTemplates,
      createdAt: now,
      lastUsed: now,
    );
    // Mentés
    final templates = await loadTemplates();
    templates.insert(0, template);
    await saveTemplates(templates);
  }

  /// Sablon frissítése
  Future<void> updateTemplate(WorkoutTemplate updatedTemplate) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == updatedTemplate.id);
    if (index != -1) {
      templates[index] = updatedTemplate;
      await saveTemplates(templates);
    }
  }

  /// Sablon törlése
  Future<void> deleteTemplate(String templateId) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == templateId);
    await saveTemplates(templates);
  }

  /// Sablon keresése ID alapján
  Future<WorkoutTemplate?> getTemplateById(String templateId) async {
    final templates = await loadTemplates();
    try {
      return templates.firstWhere((t) => t.id == templateId);
    } catch (e) {
      return null;
    }
  }

  /// Sablonok rendezése legutóbb használt szerint
  Future<List<WorkoutTemplate>> getTemplatesSortedByLastUsed() async {
    final templates = await loadTemplates();
    templates.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return templates;
  }

  // === WORKOUT SESSIONS ===

  /// Összes edzésnaplózás betöltése
  Future<List<WorkoutSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionsKey);
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((json) => WorkoutSession.fromJson(json)).toList();
    } catch (e) {
      print('Hiba a sessionök betöltésekor: $e');
      return [];
    }
  }

  /// Sessionök mentése
  Future<void> saveSessions(List<WorkoutSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, encoded);
    } catch (e) {
      print('Hiba a sessionök mentésekor: $e');
    }
  }

  /// Új edzés indítása sablonból
  Future<WorkoutSession> startWorkoutFromTemplate(WorkoutTemplate template) async {
    final now = DateTime.now();
    final sessionId = 'session_${now.millisecondsSinceEpoch}';
    final exerciseSessions = template.exerciseTemplates.map((et) {
      return ExerciseSession(
        exerciseTemplateId: et.id,
        exerciseName: et.name,
        sets: [],
      );
    }).toList();
    final session = WorkoutSession(
      id: sessionId,
      templateId: template.id,
      templateName: template.name,
      startedAt: now,
      exerciseSessions: exerciseSessions,
    );
    final updatedTemplate = template.copyWith(lastUsed: now);
    await updateTemplate(updatedTemplate);
    return session;
  }

  /// Session mentése
  Future<void> saveSession(WorkoutSession session) async {
    final sessions = await loadSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }
    await saveSessions(sessions);
  }

  /// Session befejezése és sablon frissítése az új adatokkal
  Future<void> completeSession(WorkoutSession session, {String? notes}) async {
    final completedSession = session.complete(notes: notes);
    await saveSession(completedSession);
    await _updateTemplateFromSession(completedSession);
  }

  /// Privát metódus: sablon frissítése session adatok alapján
  Future<void> _updateTemplateFromSession(WorkoutSession session) async {
    final template = await getTemplateById(session.templateId);
    if (template == null) return;
    final updatedExerciseTemplates = <ExerciseTemplate>[];
    for (final et in template.exerciseTemplates) {
      final es = session.exerciseSessions.firstWhere(
            (e) => e.exerciseTemplateId == et.id,
        orElse: () => ExerciseSession(
          exerciseTemplateId: et.id,
          exerciseName: et.name,
          sets: [],
        ),
      );
      if (es.sets.isNotEmpty) {
        final last = es.sets.last;
        updatedExerciseTemplates.add(et.updateWithSet(
          weight: last.weight,
          reps: last.reps,
          performedAt: session.completedAt ?? DateTime.now(),
        ));
      } else {
        updatedExerciseTemplates.add(et);
      }
    }
    final updatedTemplate = template.copyWith(
      exerciseTemplates: updatedExerciseTemplates,
      lastUsed: session.completedAt ?? DateTime.now(),
    );
    await updateTemplate(updatedTemplate);
  }

  /// Utolsó N nap sessionjei
  Future<List<WorkoutSession>> getRecentSessions({int days = 30}) async {
    final sessions = await loadSessions();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return sessions.where((s) => s.startedAt.isAfter(cutoff)).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  /// Befejezett edzések száma az utolsó N napban
  Future<int> getCompletedWorkoutsCount({int days = 30}) async {
    final sessions = await getRecentSessions(days: days);
    return sessions.where((s) => s.isCompleted).length;
  }

  /// Alapértelmezett sablonok létrehozása (első indításkor)
  Future<void> createDefaultTemplates() async {
    final existing = await loadTemplates();
    if (existing.isNotEmpty) return;
    final defaults = [
      await createTemplate(
        name: 'MELL',
        description: 'Mellkas és tricepsz edzés',
        exerciseNames: ['Fekvőtámasz', 'Súlyzós fekve nyomás', 'Tricepsz tolás'],
      ),
      await createTemplate(
        name: 'HÁT',
        description: 'Háti és bicepsz edzés',
        exerciseNames: ['Húzódzkodás', 'Evezés', 'Bicepsz hajlítás'],
      ),
      await createTemplate(
        name: 'LÁB',
        description: 'Alsótesti edzés',
        exerciseNames: ['Guggolás', 'Kitörés', 'Vádli emelés'],
      ),
    ];
    print('Alapértelmezett sablonok létrehozva: ${defaults.length} db');
  }
}
