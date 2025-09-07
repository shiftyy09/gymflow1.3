import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/workout_session.dart';
import '../models/exercise_template.dart';
import '../models/set_data.dart';
import '../services/workout_service.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutSession workoutSession;
  final WorkoutService workoutService;
  final List<String> customExercises;

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
  late WorkoutSession currentSession;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    currentSession = widget.workoutSession;
  }

  Future<void> _saveSession() async {
    setState(() {
      isSaving = true;
    });
    try {
      await widget.workoutService.saveSession(currentSession);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mentési hiba: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    setState(() {
      isSaving = false;
    });
  }

  Future<void> _addSet(int exerciseIndex, double weight, int reps) async {
    final newSet = SetData(weight: weight, reps: reps);
    final exerciseSession = currentSession.exerciseSessions[exerciseIndex];
    final updatedExerciseSession = exerciseSession.addSet(newSet);

    final updatedSessions = List<ExerciseSession>.from(currentSession.exerciseSessions);
    updatedSessions[exerciseIndex] = updatedExerciseSession;

    setState(() {
      currentSession = currentSession.copyWith(exerciseSessions: updatedSessions);
    });
    await _saveSession();
  }

  Future<void> _removeSet(int exerciseIndex, int setIndex) async {
    final exerciseSession = currentSession.exerciseSessions[exerciseIndex];
    final updatedExerciseSession = exerciseSession.removeSet(setIndex);

    final updatedSessions = List<ExerciseSession>.from(currentSession.exerciseSessions);
    updatedSessions[exerciseIndex] = updatedExerciseSession;

    setState(() {
      currentSession = currentSession.copyWith(exerciseSessions: updatedSessions);
    });
    await _saveSession();
  }

  Future<void> _showAddSetDialog(int exerciseIndex) async {
    final exerciseName = currentSession.exerciseSessions[exerciseIndex].exerciseName;
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$exerciseName - Új szett',
            style: const TextStyle(color: darkGray, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Súly (kg)',
                  hintText: '0.0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: primaryPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ismétlés',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: primaryPurple, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mégse', style: TextStyle(color: Colors.black.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);
              if (weight != null && weight > 0 && reps != null && reps > 0) {
                Navigator.pop(context, {'weight': weight, 'reps': reps});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kérlek adj meg érvényes értékeket!'),
                    backgroundColor: primaryPurple,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
            ),
            child: const Text(
              'Mentés',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    if (currentSession.exerciseSessions.every((es) => es.sets.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adj hozzá legalább egy szettet!'),
          backgroundColor: primaryPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edzés sikeresen befejezve!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDuration() {
    final duration = DateTime.now().difference(currentSession.startedAt);
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return hours > 0 ? '${hours}h ${rem}m' : '${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    // DEDUPLIKÁLT gyakorlatok listája
    final templateNames = currentSession.exerciseSessions.map((s) => s.exerciseName).toSet();
    final customNames = widget.customExercises.toSet();
    final allNames = {...templateNames, ...customNames}.toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lightGray, Colors.white],
          ),
        ),
        child: CustomScrollView(slivers: [
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
                      Text(
                        currentSession.templateName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Időtartam: ${_formatDuration()} • 0 szett',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.check),
                  color: Colors.white,
                  onPressed: _completeWorkout,
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final exerciseName = allNames[index];
              final hasSession = index < currentSession.exerciseSessions.length;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: cardBackground,
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withOpacity(0.08),
                      blurRadius: 13,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(20),
                  initiallyExpanded: hasSession,
                  title: Text(exerciseName,
                      style: const TextStyle(color: darkGray, fontSize: 19, fontWeight: FontWeight.bold)),
                  subtitle: hasSession && currentSession.exerciseSessions[index].sets.isNotEmpty
                      ? Text(
                      '${currentSession.exerciseSessions[index].sets.length} szett',
                      style: const TextStyle(color: primaryPurple, fontWeight: FontWeight.w600))
                      : const Text('Még nincs szett hozzáadva', style: TextStyle(color: Colors.grey)),
                  children: [
                    if (hasSession) ...[
                      ...currentSession.exerciseSessions[index].sets.asMap().entries.map((entry) {
                        final set = entry.value;
                        final setIdx = entry.key;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                'Súly: ${set.weight.toStringAsFixed(1)} kg • Ismétlés: ${set.reps}',
                                style: const TextStyle(color: darkGray, fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.redAccent,
                              iconSize: 19,
                              onPressed: () => _removeSet(index, setIdx),
                            ),
                          ]),
                        );
                      }),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddSetDialog(index),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Új szett hozzáadása', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: allNames.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _completeWorkout,
        child: const Icon(Icons.check, size: 28, color: Colors.white),
      ),
    );
  }
}