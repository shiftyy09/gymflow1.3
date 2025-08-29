import 'package:flutter/material.dart';
import 'package:gymflow/screens/workout_days_screen.dart';
import '../theme.dart';

class CustomWorkoutScreen extends StatefulWidget {
  const CustomWorkoutScreen({super.key});

  @override
  State<CustomWorkoutScreen> createState() => _CustomWorkoutScreenState();
}

class _CustomWorkoutScreenState extends State<CustomWorkoutScreen> {
  final List<String> _exercises = [];
  final TextEditingController _exerciseController = TextEditingController();

  void _addExercise() {
    final name = _exerciseController.text.trim();
    if (name.isNotEmpty) {
      setState(() => _exercises.add(name));
      _exerciseController.clear();
    }
  }

  void _startWorkout() {
    // Itt indíthatod el az edzésnapok képernyőt a felhasználó által megadott sablonnal.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => WorkoutDaysScreen(/* átadhatod az _exercises-t */)),
    );
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saját edzéssablon'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exerciseController,
                    decoration: const InputDecoration(
                      hintText: 'Gyakorlat neve',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addExercise,
                  child: const Text('Hozzáadás'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(child: Text('Még nincs gyakorlat hozzáadva.'))
                  : ListView.builder(
                      itemCount: _exercises.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(_exercises[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() => _exercises.removeAt(i));
                          },
                        ),
                      ),
                    ),
            ),
            ElevatedButton(
              onPressed: _exercises.isNotEmpty ? _startWorkout : null,
              child: const Text('Edzés indítása'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
