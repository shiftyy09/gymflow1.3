import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout.dart';
import '../constants.dart';
import '../widgets/glassmorphic_card.dart';

class WorkoutDaysScreen extends StatefulWidget {
  const WorkoutDaysScreen({Key? key}) : super(key: key);

  @override
  _WorkoutDaysScreenState createState() => _WorkoutDaysScreenState();
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
      final List<dynamic> decoded = [];
      try {
        decoded.addAll(List<dynamic>.from(workoutJson as dynamic));
      } catch (_) {}
      final loaded = decoded.map((json) => WorkoutDay.fromJson(json)).toList();
      setState(() {
        workoutDays = loaded;
      });
    }
  }

  Future<void> _saveWorkoutDays() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = workoutDays.isEmpty
        ? '[]'
        : workoutDays.map((e) => e.toJson()).toString();
    await prefs.setString('workoutDays', encoded);
  }

  void _ujEdzesNap() async {
    final szovegController = TextEditingController();

    final eredmeny = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Új edzésnap'),
        content: TextField(
          controller: szovegController,
          decoration: const InputDecoration(hintText: 'Pl. Mell és bicepsz'),
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
              if (szovegController.text.trim().isNotEmpty) {
                Navigator.pop(context, szovegController.text.trim());
              }
            },
          ),
        ],
      ),
    );

    if (eredmeny != null) {
      setState(() {
        workoutDays.insert(
            0,
            WorkoutDay(
              name: eredmeny,
              date: DateTime.now(),
              exercises: [],
            ));
      });
      await _saveWorkoutDays();
    }
  }

  void _torolEdzesNap(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Biztos törlöd?'),
        content: Text('Törlöd az edzésnapot: "${workoutDays[index].name}"?'),
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

  String _formatDatum(DateTime datum) =>
      '${datum.year}.${datum.month.toString().padLeft(2, '0')}.${datum.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Helló, $userName!'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
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
                      'Legyen ez az első edzésed!',
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
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(day.name),
                      subtitle: Text('${day.exercises.length} gyakorlat — ${_formatDatum(day.date)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _torolEdzesNap(index),
                      ),
                      onTap: () {
                        // Itt később nyisd meg a részleteket
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ujEdzesNap,
        child: const Icon(Icons.add),
      ),
    );
  }
}
