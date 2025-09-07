import 'package:flutter/material.dart';
import '../models/workout_session.dart';

class WorkoutDayScreen extends StatefulWidget {
  final WorkoutSession session;

  const WorkoutDayScreen({
    super.key,
    required this.session,
  });

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  final TextEditingController exerciseController = TextEditingController();
  final List<String> dayExercises = [];
  bool _isInitialized = false; // Guard a duplikáció ellen

  @override
  void initState() {
    super.initState();

    // Csak egyszer fusson le az inicializálás
    if (!_isInitialized) {
      _isInitialized = true;

      // Alapgyakorlatok hozzáadása (ha vannak)
      if (widget.session.exerciseSessions.isNotEmpty) {
        for (var exercise in widget.session.exerciseSessions) {
          dayExercises.add(exercise.exerciseName);
        }
      }
    }
  }

  void addExercise() {
    final name = exerciseController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        // Deduplikáció - csak akkor adjuk hozzá, ha még nincs benne
        if (!dayExercises.contains(name)) {
          dayExercises.add(name);
        }
      });
      exerciseController.clear();
    }
  }

  void removeExercise(int index) {
    setState(() {
      dayExercises.removeAt(index);
    });
  }

  // Deduplikált lista visszaadása
  List<String> get uniqueExercises {
    return dayExercises.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = uniqueExercises;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nap gyakorlatok'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Gyakorlat hozzáadása
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: exerciseController,
                    decoration: const InputDecoration(
                      hintText: 'Gyakorlat neve...',
                      fillColor: Colors.white24,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => addExercise(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: addExercise,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  child: const Text('Hozzáadás'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gyakorlatok listája
            Expanded(
              child: exercises.isEmpty
                  ? const Center(
                child: Text(
                  'Még nincs gyakorlat hozzáadva.\nAdd meg az első gyakorlatot!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, i) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(exercises[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => removeExercise(i),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Mentés gomb
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, exercises);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'Gyakorlatok mentése',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    exerciseController.dispose();
    super.dispose();
  }
}