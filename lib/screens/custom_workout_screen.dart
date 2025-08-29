import 'package:flutter/material.dart';
import '../theme.dart';
import 'custom_day_exercises_screen.dart';
import 'workout_days_screen.dart';

class CustomWorkoutScreen extends StatefulWidget {
  const CustomWorkoutScreen({super.key});

  @override
  State<CustomWorkoutScreen> createState() => _CustomWorkoutScreenState();
}

class _CustomWorkoutScreenState extends State<CustomWorkoutScreen> {
  final List<Map<String, dynamic>> _workoutDays = [];
  final TextEditingController _dayController = TextEditingController();

  void _addDay() {
    final dayName = _dayController.text.trim();
    if (dayName.isNotEmpty) {
      setState(() {
        _workoutDays.add({
          'name': dayName,
          'exercises': <String>[], // Üres gyakorlatok lista
        });
      });
      _dayController.clear();
    }
  }

  void _removeDay(int index) {
    setState(() => _workoutDays.removeAt(index));
  }

  void _editDayExercises(int dayIndex) async {
    final dayData = _workoutDays[dayIndex];
    final updatedExercises = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomDayExercisesScreen(
          dayName: dayData['name'],
          initialExercises: List<String>.from(dayData['exercises']),
        ),
      ),
    );

    if (updatedExercises != null) {
      setState(() {
        _workoutDays[dayIndex]['exercises'] = updatedExercises;
      });
    }
  }

  void _startWorkout() {
    if (_workoutDays.isNotEmpty) {
      // Itt navigálhatsz vissza vagy indítsd el az edzést
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkoutDaysScreen()),
      );
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saját edzéssablon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edzésnapok létrehozása',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dayController,
                    decoration: const InputDecoration(
                      hintText: 'Nap neve (pl. Hétfő, Mell nap)',
                      fillColor: Colors.white24,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addDay,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  child: const Text('Hozzáadás'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _workoutDays.isEmpty
                  ? const Center(
                child: Text(
                  'Még nincs edzésnap hozzáadva.\nAdd meg az első napot!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _workoutDays.length,
                itemBuilder: (_, i) {
                  final day = _workoutDays[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        day['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${day['exercises'].length} gyakorlat',
                        style: const TextStyle(color: primaryPurple),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: primaryPurple),
                            onPressed: () => _editDayExercises(i),
                            tooltip: 'Gyakorlatok szerkesztése',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeDay(i),
                            tooltip: 'Nap törlése',
                          ),
                        ],
                      ),
                      onTap: () => _editDayExercises(i),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _workoutDays.isNotEmpty ? _startWorkout : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: primaryPurple,
                ),
                child: const Text(
                  'Sablon mentése 🚀',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}