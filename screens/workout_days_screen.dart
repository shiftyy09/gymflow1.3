import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glassmorphic_card.dart';

import '../models/workout.dart';
import '../constants.dart';

class WorkoutDaysScreen extends StatefulWidget {
  const WorkoutDaysScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutDaysScreen> createState() => _WorkoutDaysScreenState();
}

class _WorkoutDaysScreenState extends State<WorkoutDaysScreen> {
  List<WorkoutDay> workoutDays = [];
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadWorkoutDays();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('nickname') ?? 'Sportoló';
    });
  }

  Future<void> _loadWorkoutDays() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutJson = prefs.getString('workoutDays');

    if (workoutJson != null && workoutJson.isNotEmpty) {
      final List decoded = List<Map<String, dynamic>>.from(
        (workoutJson == '[]') ? [] : List<dynamic>.from(workoutJson as dynamic),
      );
      setState(() {
        workoutDays = decoded.map((e) => WorkoutDay.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveWorkoutDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'workoutDays',
      workoutDays.map((e) => e.toJson()).toList().toString(),
    );
  }

  void _startNewWorkout() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Új edzésnap'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Pl. Mell & Tricepsz'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Mégse'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Indítás'),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
          ),
        ],
      ),
    );

    if (name != null) {
      setState(() {
        workoutDays.insert(
            0,
            WorkoutDay(
              name: name,
              date: DateTime.now(),
              exercises: [],
            ));
      });
      await _saveWorkoutDays();
    }
  }

  void _deleteWorkout(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Biztos törlöd?'),
        content: Text('Törlöd a "${workoutDays[index].name}" edzésnapot?'),
        actions: [
          TextButton(
            child: const Text('Mégse'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                workoutDays.removeAt(index);
              });
              _saveWorkoutDays();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Helló, $userName!'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [gradientStart, gradientEnd]),
        ),
        child: workoutDays.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.fitness_center, size: 90, color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Kezdd el az első edzésnapod!',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: workoutDays.length,
                itemBuilder: (context, index) {
                  final day = workoutDays[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(day.name),
                      subtitle: Text(
                          '${day.exercises.length} gyakorlat  •  ${_formatDate(day.date)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteWorkout(index),
                      ),
                      onTap: () {
                        // Ide jön majd a WorkoutDetailScreen-re navigálás
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewWorkout,
        child: const Icon(Icons.add),
      ),
    );
  }
}
