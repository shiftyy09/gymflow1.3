import 'package:flutter/material.dart';
import '../theme.dart';
import 'custom_workout_screen.dart';
import 'workout_days_screen.dart';
import '../services/workout_service.dart';
import 'custom_workout_screen.dart';

class WorkoutStartScreen extends StatefulWidget {
  const WorkoutStartScreen({super.key});

  @override
  State<WorkoutStartScreen> createState() => _WorkoutStartScreenState();
}

class _WorkoutStartScreenState extends State<WorkoutStartScreen> {
  final WorkoutService _workoutService = WorkoutService();
  bool _loading = false;

  Future<void> _startAutoWorkout() async {
    setState(() => _loading = true);
    await _workoutService.createDefaultTemplates();
    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutDaysScreen()),
    );
  }

  void _startCustomWorkout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CustomWorkoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("WorkoutStartScreen build hívva, loading: $_loading");  // DEBUG
    return Scaffold(
      appBar: AppBar(title: const Text('Edzés indítása')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Automatikus gyakorlat összeállítás'),
              onPressed: _startAutoWorkout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Saját edzés összeállítása'),
              onPressed: _startCustomWorkout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
