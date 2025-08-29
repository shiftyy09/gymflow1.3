import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../constants.dart';
import '../widgets/glassmorphic_card.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutDay workoutDay;
  final ValueChanged<WorkoutDay> onSave;

  const WorkoutDetailScreen({
    Key? key,
    required this.workoutDay,
    required this.onSave,
  }) : super(key: key);

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late WorkoutDay _currentWorkout;

  @override
  void initState() {
    super.initState();
    _currentWorkout = WorkoutDay(
      name: widget.workoutDay.name,
      date: widget.workoutDay.date,
      exercises: widget.workoutDay.exercises
          .map((e) => Exercise(
                name: e.name,
                tip: e.tip,
                sets: List<SetData>.from(e.sets),
              ))
          .toList(),
    );
  }

  void _addSet(int exerciseIndex, double weight, int reps) {
    setState(() {
      _currentWorkout.exercises[exerciseIndex].sets.add(SetData(weight: weight, reps: reps));
    });
    widget.onSave(_currentWorkout);
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _currentWorkout.exercises[exerciseIndex].sets.removeAt(setIndex);
    });
    widget.onSave(_currentWorkout);
  }

  Future<void> _showAddSetDialog(int exerciseIndex) async {
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${_currentWorkout.exercises[exerciseIndex].name} - Új sorozat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Súly (kg)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryPurple, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Ismétlés',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryPurple, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Mégse'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Mentés'),
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);
              if (weight != null && weight > 0 && reps != null && reps > 0) {
                Navigator.pop(context, {'weight': weight, 'reps': reps});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Érvényes számokat adj meg!'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );

    if (result != null) {
      _addSet(exerciseIndex, result['weight'], result['reps']);
    }
  }

  void _addExercise() {
    final exerciseController = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Új gyakorlat hozzáadása', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: exerciseController,
          decoration: const InputDecoration(hintText: 'Gyakorlat neve', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Mégse'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Hozzáadás'),
            onPressed: () {
              final name = exerciseController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _currentWorkout.exercises.add(Exercise(name: name, tip: '', sets: []));
                });
                widget.onSave(_currentWorkout);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adj meg egy nevet!'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _removeExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Gyakorlat törlése', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Biztos törlöd a "${_currentWorkout.exercises[index].name}" gyakorlatot?'),
        actions: [
          TextButton(child: const Text('Mégse'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Törlés', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                _currentWorkout.exercises.removeAt(index);
              });
              widget.onSave(_currentWorkout);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _saveWorkout() {
    if (_currentWorkout.exercises.isEmpty ||
        !_currentWorkout.exercises.any((e) => e.sets.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adj hozzá legalább egy sorozatot!'), backgroundColor: Colors.red),
      );
      return;
    }
    widget.onSave(_currentWorkout);
    Navigator.pop(context);
  }

  String _formatDatum(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentWorkout.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWorkout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [gradientStart, gradientEnd]),
        ),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_currentWorkout.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Még nincs gyakorlat hozzáadva', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ..._currentWorkout.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ExpansionTile(
                  title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: exercise.tip.isNotEmpty ? Text('Tipp: ${exercise.tip}') : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _removeExercise(index),
                  ),
                  children: [
                    if (exercise.sets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Nincs hozzá sorozat', textAlign: TextAlign.center),
                      ),
                    ...exercise.sets.asMap().entries.map((setEntry) {
                      final setIndex = setEntry.key;
                      final set = setEntry.value;
                      return ListTile(
                        title: Text('Súly: ${set.weight.toStringAsFixed(1)} kg - Ismétlés: ${set.reps}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _removeSet(index, setIndex),
                        ),
                      );
                    }).toList(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Új sorozat hozzáadása'),
                        onPressed: () => _showAddSetDialog(index),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Új gyakorlat hozzáadása'),
                onPressed: _addExercise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
