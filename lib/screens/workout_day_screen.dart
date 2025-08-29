import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../models/workout_session.dart';

class WorkoutDayScreen extends StatefulWidget {
  final WorkoutSession session;
  const WorkoutDayScreen({super.key, required this.session});

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  final _controller = TextEditingController();
  final List<String> _dayExercises = [];

  void _addExercise() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      setState(() => _dayExercises.add(name));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nap gyakorlatok')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Gyakorlat neve'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addExercise),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _dayExercises.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(_dayExercises[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _dayExercises.removeAt(i)),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _dayExercises),
              child: const Text('Mentés és folytatás'),
            ),
          ],
        ),
      ),
    );
  }
}

