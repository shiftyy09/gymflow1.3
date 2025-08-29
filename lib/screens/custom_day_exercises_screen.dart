import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/workout_service.dart';
import 'workout_detail_screen.dart';

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
  final WorkoutService _service = WorkoutService();

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.initialExercises);
    _exerciseController.addListener(() => setState(() {}));
  }

  void _addExercise() {
    final name = _exerciseController.text.trim();
    if (name.isNotEmpty && !_exercises.contains(name)) {
      _exercises.add(name);
      _exerciseController.clear();
      setState(() {});
    }
  }

  void _removeExercise(int i) {
    _exercises.removeAt(i);
    setState(() {});
  }

  Future<void> _saveDayAndStartSession() async {
    if (_exercises.isEmpty) return;

    // 1. Egyéni napot sablonként elmentjük
    await _service.createCustomDay(
      dayName: widget.dayName,
      exercises: _exercises,
    );

    // 2. Betöltjük az újonnan mentett sablont
    final templates = await _service.getTemplatesSortedByLastUsed();
    final custom = templates.first; // a legutoljára mentett

    // 3. Indítunk egy WorkoutSession-t ebből a sablonból
    final session = await _service.startWorkoutFromTemplate(custom);

    // 4. Navigálunk a részletező képernyőre
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(
          workoutSession: session,
          workoutService: _service,
          customExercises: _exercises,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _exerciseController
      ..removeListener(() {})
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _exercises.isNotEmpty || _exerciseController.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dayName} – Gyakorlatok'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                hintText: 'Gyakorlat neve...',
                prefixIcon: Icon(Icons.fitness_center),
                fillColor: Colors.white24,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _addExercise(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _exercises.isEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Nincsenek gyakorlatok még.'),
                  SizedBox(height: 8),
                  Text(
                    'Adj hozzá legalább 1 gyakorlatot a mentéshez.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ],
              )
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
            ElevatedButton(
              onPressed: canSave ? () {
                if (_exerciseController.text
                    .trim()
                    .isNotEmpty) {
                  _addExercise();
                }
                _saveDayAndStartSession();
              }
              : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: canSave ? primaryPurple : Colors.grey,
              ),
              child: const Text('Gyakorlatok mentése'),
            ),
          ],
        ),
      ),
    );
  }
}
