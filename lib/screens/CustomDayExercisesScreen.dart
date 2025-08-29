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

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dayName} - Gyakorlatok'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _exercises),
            child: const Text(
              'Mentés',
              style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gyakorlatok hozzáadása: ${widget.dayName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exerciseController,
                    decoration: const InputDecoration(
                      hintText: 'Gyakorlat neve (pl. Fekvenyomás)',
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
                  onPressed: _addExercise,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  child: const Text('Hozzáadás'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _exercises.isEmpty
                  ? const Center(
                child: Text(
                  'Még nincs gyakorlat hozzáadva.\nAdd meg az első gyakorlatot!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (_, i) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(_exercises[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeExercise(i),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _exercises),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'Gyakorlatok mentése ✓',
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
