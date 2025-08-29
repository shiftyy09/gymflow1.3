import 'package:flutter/material.dart';
import '../theme.dart';
import 'custom_day_exercises_screen.dart';

class CustomWorkoutScreen extends StatefulWidget {
  const CustomWorkoutScreen({super.key});

  @override
  State<CustomWorkoutScreen> createState() => _CustomWorkoutScreenState();
}

class _CustomWorkoutScreenState extends State<CustomWorkoutScreen> {
  final TextEditingController _dayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dayController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _dayController
      ..removeListener(() {})
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayName = _dayController.text.trim();
    final canProceed = dayName.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saját edzésnap létrehozása'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _dayController,
              decoration: const InputDecoration(
                hintText: 'Nap neve (pl. Hétfő, Mell nap)',
                prefixIcon: Icon(Icons.today),
                fillColor: Colors.white24,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            if (!canProceed)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Folytatáshoz adj meg egy edzésnap nevet.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: canProceed
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomDayExercisesScreen(
                      dayName: dayName,
                      initialExercises: const [],
                    ),
                  ),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: canProceed ? primaryPurple : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Edzésnap mentése', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

