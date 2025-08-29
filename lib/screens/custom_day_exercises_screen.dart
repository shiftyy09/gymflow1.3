import 'package:flutter/material.dart';
import '../theme.dart';

class CustomDayExercisesScreen extends StatefulWidget {
  final String dayName;
  final List<String> initialExercises;

  const CustomDayExercisesScreen({
    super.key,
    required this.dayName,
    required this.initialExercises,
  });

  @override
  State<CustomDayExercisesScreen> createState() => _CustomDayExercisesScreenState();
}

class _CustomDayExercisesScreenState extends State<CustomDayExercisesScreen> {
  late List<String> _exercises;
  final TextEditingController _exerciseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.initialExercises);
  }

  void _addExercise() {
    final exerciseName = _exerciseController.text.trim();
    if (exerciseName.isNotEmpty) {
      setState(() => _exercises.add(exerciseName));
      _exerciseController.clear();
    }
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _saveAndGoBack() {
    Navigator.pop(context, _exercises);
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _exercises.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dayName} – Gyakorlatok'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: canSave ? _saveAndGoBack : null,
            child: Text(
              'Mentés',
              style: TextStyle(
                color: canSave ? primaryPurple : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                hintText: 'Gyakorlat neve...',
                fillColor: Colors.white24,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              onSubmitted: (_) => _addExercise(),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                canSave
                    ? '${_exercises.length} gyakorlat készen áll a mentésre.'
                    : 'Adj hozzá legalább 1 gyakorlatot a mentéshez.',
                style: TextStyle(
                  color: canSave ? Colors.green : Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: canSave ? _saveAndGoBack : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: canSave ? Colors.green : Colors.grey,
              ),
              child: const Text('Gyakorlatok mentése'),
            ),
          ],
        ),
      ),
    );
  }
}
