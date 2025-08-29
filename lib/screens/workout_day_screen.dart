import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../services/workout_service.dart';
import 'workout_detail_screen.dart';

class WorkoutDayScreen extends StatefulWidget {
  final WorkoutSession session;
  const WorkoutDayScreen({super.key, required this.session});

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  late List<String> _exercises;
  final TextEditingController _controller = TextEditingController();
  final WorkoutService _service = WorkoutService();

  @override
  void initState() {
    super.initState();
    // Kezdetben a sablonból örökölt gyakorlatok nevei
    _exercises = widget.session.exerciseSessions
        .map((es) => es.exerciseName)
        .toList();
  }

  void _addExercise() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _exercises.add(name);
      _controller.clear();
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _proceedToDetail() async {
    // Frissítjük a session exerciseSessions listát
    final updatedSessions = _exercises.map((name) {
      final existing = widget.session.exerciseSessions.firstWhere(
            (es) => es.exerciseName == name,
        orElse: () => ExerciseSession(
          exerciseTemplateId: 'custom_$name',
          exerciseName: name,
          sets: [],
        ),
      );
      return existing;
    }).toList();

    final updatedSession =
    widget.session.copyWith(exerciseSessions: updatedSessions);
    await _service.saveSession(updatedSession);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(
          workoutSession: updatedSession,
          workoutService: _service,
          customExercises: _exercises,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _exercises.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.session.templateName} – Gyakorlatok'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dinamikus sablonkártya
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(widget.session.templateName),
              ),
            ),

            // Új gyakorlat bevitele
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Új gyakorlat neve...',
                prefixIcon: Icon(Icons.add),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addExercise(),
            ),
            const SizedBox(height: 12),

            // Gyakorlatok listája
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(child: Text('Nincsenek gyakorlatok még.'))
                  : ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(_exercises[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeExercise(i),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Egyetlen alsó gomb
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: canProceed ? _proceedToDetail : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: canProceed ? Colors.green : Colors.grey,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Tovább az edzéshez',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
