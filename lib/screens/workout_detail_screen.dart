import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/workout_session.dart';
import '../models/exercise_template.dart';
import '../models/set_data.dart';
import '../services/workout_service.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutSession workoutSession;
  final WorkoutService workoutService;
  final List<String> customExercises; // típusosítva

  const WorkoutDetailScreen({
    super.key,
    required this.workoutSession,
    required this.workoutService,
    this.customExercises = const [],
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late WorkoutSession _currentSession;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.workoutSession;
  }

  Future<void> _saveSession() async {
    setState(() => _isSaving = true);
    try {
      await widget.workoutService.saveSession(_currentSession);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mentési hiba: $e'), backgroundColor: Colors.redAccent),
      );
    }
    setState(() => _isSaving = false);
  }

  Future<void> _addSet(int exerciseIndex, double weight, int reps) async {
    final newSet = SetData(weight: weight, reps: reps);
    final exerciseSession = _currentSession.exerciseSessions[exerciseIndex];
    final updatedExerciseSession = exerciseSession.addSet(newSet);
    final List<ExerciseSession> updatedSessions = List.from(_currentSession.exerciseSessions)
      ..[exerciseIndex] = updatedExerciseSession;
    setState(() {
      _currentSession = _currentSession.copyWith(exerciseSessions: updatedSessions);
    });
    await _saveSession();
  }

  Future<void> _removeSet(int exerciseIndex, int setIndex) async {
    final exerciseSession = _currentSession.exerciseSessions[exerciseIndex];
    final updatedExerciseSession = exerciseSession.removeSet(setIndex);
    final List<ExerciseSession> updatedSessions = List.from(_currentSession.exerciseSessions)
      ..[exerciseIndex] = updatedExerciseSession;
    setState(() {
      _currentSession = _currentSession.copyWith(exerciseSessions: updatedSessions);
    });
    await _saveSession();
  }

  Future<void> _showAddSetDialog(int exerciseIndex) async {
    final exerciseName = _currentSession.exerciseSessions[exerciseIndex].exerciseName;
    final weightController = TextEditingController();
    final repsController = TextEditingController();
    final template = await widget.workoutService.getTemplateById(_currentSession.templateId);
    final exerciseTemplate = template?.exerciseTemplates.firstWhere(
          (et) => et.id == _currentSession.exerciseSessions[exerciseIndex].exerciseTemplateId,
      orElse: () => ExerciseTemplate(id: '', name: exerciseName),
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$exerciseName – Új szett', style: const TextStyle(color: darkGray, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exerciseTemplate?.hasHistory == true) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: lightPurple.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('Utoljára: ${exerciseTemplate!.lastPerformanceText}',
                          style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.w600)),
                      if (exerciseTemplate.maxWeight != null)
                        Text(exerciseTemplate.maxPerformanceText, style: const TextStyle(color: primaryPurple, fontSize: 12)),
                    ],
                  ),
                ),
              ],
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Súly (kg)',
                  hintText: exerciseTemplate?.lastWeight?.toStringAsFixed(1) ?? '0.0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: primaryPurple, width: 2),
                  ),
                ),
                onTap: () {
                  if (exerciseTemplate?.lastWeight != null && weightController.text.isEmpty) {
                    weightController.text = exerciseTemplate!.lastWeight!.toStringAsFixed(1);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ismétlés',
                  hintText: exerciseTemplate?.lastReps?.toString() ?? '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: primaryPurple, width: 2),
                  ),
                ),
                onTap: () {
                  if (exerciseTemplate?.lastReps != null && repsController.text.isEmpty) {
                    repsController.text = exerciseTemplate!.lastReps!.toString();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Mégse', style: TextStyle(color: Colors.black.withOpacity(0.6)))),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [accentPink, primaryPurple])),
            child: ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text);
                final reps = int.tryParse(repsController.text);
                if (weight != null && weight > 0 && reps != null && reps > 0) {
                  Navigator.pop(context, {'weight': weight, 'reps': reps});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kérlek adj meg érvényes értékeket!'), backgroundColor: primaryPurple, behavior: SnackBarBehavior.floating),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              child: const Text('Mentés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      await _addSet(exerciseIndex, result['weight'], result['reps']);
    }
  }

  Future<void> _completeWorkout() async {
    if (!_currentSession.hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adj hozzá legalább egy szettet!'), backgroundColor: primaryPurple, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final notesController = TextEditingController();
    final notes = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edzés befejezése 🎉', style: TextStyle(color: darkGray, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Szuper munka! ${_currentSession.totalSets} szett végrehajtva.', style: const TextStyle(color: darkGray)),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Megjegyzések (opcionális)',
                hintText: 'Pl. jól ment, nehéz volt...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: primaryPurple, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tovább edzek')),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [accentPink, primaryPurple])),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, notesController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              child: const Text('Befejezés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
    if (notes != null) {
      setState(() => _isSaving = true);
      try {
        await widget.workoutService.completeSession(_currentSession, notes: notes.isEmpty ? null : notes);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edzés sikeresen befejezve! 🎉'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hiba a befejezéskor: $e'), backgroundColor: Colors.redAccent));
      }
      setState(() => _isSaving = false);
    }
  }

  String _formatDuration() {
    final duration = DateTime.now().difference(_currentSession.startedAt);
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return hours > 0 ? '${hours}h ${rem}m' : '${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final templateNames = _currentSession.exerciseSessions.map((s) => s.exerciseName);
    final allNames = [...templateNames, ...widget.customExercises];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [lightGray, Colors.white]),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [gradientStart, gradientEnd])),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 36, 20, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(_currentSession.templateName,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('Időtartam: ${_formatDuration()} • ${_currentSession.totalSets} szett',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_isSaving)
                  const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                else
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.08)])),
                    child: IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: _completeWorkout),
                  ),
              ],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final exerciseName = allNames[index];
                  final hasSession = index < _currentSession.exerciseSessions.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: cardBackground,
                      boxShadow: [BoxShadow(color: primaryPurple.withOpacity(0.08), blurRadius: 13, spreadRadius: 1, offset: const Offset(0, 4))],
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(20),
                      initiallyExpanded: hasSession,
                      title: Text(exerciseName, style: const TextStyle(color: darkGray, fontSize: 19, fontWeight: FontWeight.bold)),
                      subtitle: hasSession && _currentSession.exerciseSessions[index].sets.isNotEmpty
                          ? Text(
                        '${_currentSession.exerciseSessions[index].sets.length} szett • Max: ${_currentSession.exerciseSessions[index].maxWeightInSession?.toStringAsFixed(1) ?? 0} kg',
                        style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.w600),
                      )
                          : const Text('Még nincs szett hozzáadva', style: TextStyle(color: Colors.grey)),
                      children: [
                        if (hasSession)
                          ..._currentSession.exerciseSessions[index].sets.asMap().entries.map((entry) {
                            final set = entry.value;
                            final setIdx = entry.key;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [gradientStart.withOpacity(0.08), gradientEnd.withOpacity(0.09)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('Súly: ${set.weight.toStringAsFixed(1)} kg • Ismétlés: ${set.reps}',
                                        style: const TextStyle(color: Color(0xFF212327), fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.1)),
                                  ),
                                  IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 19), onPressed: () => _removeSet(index, setIdx)),
                                ],
                              ),
                            );
                          }),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [lightPurple, primaryPurple])),
                            child: TextButton.icon(
                              onPressed: () => _showAddSetDialog(index),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Új szett hozzáadása', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: allNames.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.35), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _completeWorkout,
          child: const Icon(Icons.check, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}
