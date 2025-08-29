import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const GymFlowApp());

const Color customRed = Color(0xFFFF3131);

// --- Adatmodellek JSON serializálással ---
class SetData {
  double weight;
  int reps;

  SetData({required this.weight, required this.reps});

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'reps': reps,
  };

  static SetData fromJson(Map<String, dynamic> json) => SetData(
    weight: (json['weight']).toDouble(),
    reps: json['reps'],
  );
}

class Exercise {
  String name;
  List<SetData> sets;
  String tip;

  Exercise({required this.name, this.sets = const [], this.tip = ''});

  double? get previousWeight => sets.isNotEmpty ? sets.last.weight : null;

  Map<String, dynamic> toJson() => {
    'name': name,
    'tip': tip,
    'sets': sets.map((e) => e.toJson()).toList(),
  };

  static Exercise fromJson(Map<String, dynamic> json) => Exercise(
    name: json['name'],
    tip: json['tip'],
    sets: (json['sets'] as List<dynamic>)
        .map((e) => SetData.fromJson(e))
        .toList(),
  );
}

class WorkoutDay {
  String name;
  DateTime date;
  List<Exercise> exercises;

  WorkoutDay({required this.name, required this.date, required this.exercises});

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  static WorkoutDay fromJson(Map<String, dynamic> json) => WorkoutDay(
    name: json['name'],
    date: DateTime.parse(json['date']),
    exercises: (json['exercises'] as List<dynamic>)
        .map((e) => Exercise.fromJson(e))
        .toList(),
  );
}

// -------------------------------------------------------------------

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GYMFLOW Napló',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.dark(primary: customRed),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Splash Screen animált logóval ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showLogo = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showLogo = true);

    await Future.delayed(const Duration(milliseconds: 2500));
    setState(() => _showLogo = false);

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showForm = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
              ),
            ),
          ),
          if (!_showForm)
            Center(
              child: AnimatedOpacity(
                opacity: _showLogo ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: AnimatedScale(
                  scale: _showLogo ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 800),
                  child: Image.asset(
                    'assets/gymflow_logo.png',
                    height: 360,
                  ),
                ),
              ),
            ),
          if (_showForm)
            AnimatedOpacity(
              opacity: _showForm ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: const BmiForm(),
            ),
        ],
      ),
    );
  }
}

// --- BMI kalkulátor és motiváció + becenév + napi fehérje ---

class BmiForm extends StatefulWidget {
  const BmiForm({super.key});

  @override
  State<BmiForm> createState() => _BmiFormState();
}

class _BmiFormState extends State<BmiForm> {
  final _nicknameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedLevel = 'Kezdő';

  final List<String> _levels = ['Kezdő', 'Haladó', 'Profi'];

  double? _bmi;
  String _motivation = '';
  bool _showResult = false;
  double? _recommendedProtein;

  @override
  void initState() {
    super.initState();
    _loadBmiData();
  }

  Future<void> _loadBmiData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _nicknameController.text = prefs.getString('nickname') ?? '';
      _weightController.text = prefs.getString('weight') ?? '';
      _heightController.text = prefs.getString('height') ?? '';
      _selectedLevel = prefs.getString('level') ?? 'Kezdő';

      final savedBmi = prefs.getDouble('bmi');
      final savedMotivation = prefs.getString('motivation');
      final savedProtein = prefs.getDouble('protein');
      if (savedBmi != null && savedMotivation != null) {
        _bmi = savedBmi;
        _motivation = savedMotivation;
        _showResult = true;
      }
      if (savedProtein != null) {
        _recommendedProtein = savedProtein;
      }
    });
  }

  Future<void> _saveBmiData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nicknameController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('level', _selectedLevel);
    if (_bmi != null) await prefs.setDouble('bmi', _bmi!);
    await prefs.setString('motivation', _motivation);
    if (_recommendedProtein != null) await prefs.setDouble('protein', _recommendedProtein!);
  }

  void _calculateBMI() {
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _nicknameController.text.isEmpty) {
      setState(() => _showResult = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adj meg becenevet, testsúlyt és magasságot!')),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text);
    final heightCm = double.tryParse(_heightController.text);

    if (weight == null || heightCm == null || weight <= 0 || heightCm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek, adj érvényes számokat!')),
      );
      return;
    }

    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);

    String motivation;
    switch (_selectedLevel) {
      case 'Kezdő':
        motivation = "${_nicknameController.text}, minden nagy út egy lépéssel kezdődik! 🌟\nNe izgulj, lassan haladj, és élvezd a folyamatot.";
        break;
      case 'Haladó':
        motivation = "${_nicknameController.text}, szuper munka eddig! 💪\nMost jön az igazi kihívás - lépj ki a komfortzónádból!";
        break;
      case 'Profi':
        motivation = "${_nicknameController.text}, tisztelet! 🚀\nTe már tudod a titkot - következetesség és kitartás.";
        break;
      default:
        motivation = "${_nicknameController.text}, szuper vagy! 🔥";
    }

    final protein = double.parse((weight * 1.8).toStringAsFixed(1)); // 1.8g/kg napi ajánlás

    setState(() {
      _bmi = double.parse(bmi.toStringAsFixed(1));
      _motivation = motivation;
      _recommendedProtein = protein;
      _showResult = true;
    });

    _saveBmiData();
  }

  void _goToWorkoutDays() {
    if (_showResult) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WorkoutDaysScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Előbb számold ki a BMI-t!')),
      );
    }
  }

  Widget _buildInputCard(
      String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white60),
          hintStyle: const TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Milyen szinten vagy?',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: _levels.map((level) {
              final isSelected = _selectedLevel == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLevel = level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? customRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? customRed : Colors.white30,
                      ),
                    ),
                    child: Text(
                      level,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({required VoidCallback onStartTraining}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: customRed.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'BMI: ',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$_bmi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: customRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _motivation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (_recommendedProtein != null)
            Text(
              'Ajánlott napi fehérjebevitel: $_recommendedProtein g',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartTraining,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: customRed,
                side: BorderSide(color: customRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Kezdjük az edzést! 🚀',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'GYMFLOW',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: customRed,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Kezdjünk az alapokkal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildInputCard('Becenév', _nicknameController, 'Barát'),
            const SizedBox(height: 16),
            _buildInputCard('Testsúly (kg)', _weightController, '70', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildInputCard('Magasság (cm)', _heightController, '175', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildLevelSelector(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _calculateBMI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: customRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Számítás',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_showResult)
              _buildResultCard(onStartTraining: _goToWorkoutDays),
          ],
        ),
      ),
    );
  }
}

// --- Edzésnapok lista és kezelése ---

class WorkoutDaysScreen extends StatefulWidget {
  const WorkoutDaysScreen({super.key});

  @override
  State<WorkoutDaysScreen> createState() => _WorkoutDaysScreenState();
}

class _WorkoutDaysScreenState extends State<WorkoutDaysScreen> {
  List<WorkoutDay> workoutDays = [];

  @override
  void initState() {
    super.initState();
    _loadWorkoutDays();
  }

  Future<void> _loadWorkoutDays() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutDaysJson = prefs.getString('workoutDays');
    if (workoutDaysJson != null) {
      final List<dynamic> decoded = jsonDecode(workoutDaysJson);
      setState(() {
        workoutDays = decoded.map((e) => WorkoutDay.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveWorkoutDays() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(workoutDays.map((e) => e.toJson()).toList());
    await prefs.setString('workoutDays', encoded);
  }

  void _startNewWorkout() async {
    final workoutNameController = TextEditingController();

    String? enteredName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edzésnap megnevezése'),
        content: TextField(
          controller: workoutNameController,
          decoration: const InputDecoration(hintText: 'Pl. Mell nap'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              if (workoutNameController.text.trim().isNotEmpty) {
                Navigator.pop(context, workoutNameController.text.trim());
              }
            },
            child: const Text('Indítás'),
          ),
        ],
      ),
    );

    if (enteredName != null) {
      final newWorkout = WorkoutDay(
        name: enteredName,
        date: DateTime.now(),
        exercises: [
          Exercise(name: 'Lábtoló gép', tip: 'Ügyelj a helyes lábtartásra!'),
          Exercise(name: 'Fekvenyomó gép', tip: 'Ne tartsd vissza a lélegzeted!'),
          Exercise(name: 'Evezőgép', tip: 'Tartsd a tested egyenesen!'),
        ],
      );

      setState(() {
        workoutDays.insert(0, newWorkout);
      });

      _saveWorkoutDays();

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          workoutDay: newWorkout,
          onSave: (updatedWorkout) {
            setState(() {
              final index = workoutDays.indexOf(newWorkout);
              if (index != -1) workoutDays[index] = updatedWorkout;
              _saveWorkoutDays();
            });
          },
        ),
      ));
    }
  }

  void _deleteWorkout(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biztos törlöd az edzésnapot?'),
        content: Text('A(z) "${workoutDays[index].name}" edzésnap törlésre kerül.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workoutDays.removeAt(index);
                _saveWorkoutDays();
              });
              Navigator.pop(context);
            },
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edzésnapok'),
        backgroundColor: customRed,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: customRed,
        onPressed: _startNewWorkout,
        child: const Icon(Icons.add),
        tooltip: 'Új edzésnap indítása',
      ),
      body: workoutDays.isEmpty
          ? const Center(
        child: Text(
          'Nincsenek elmentett edzésnapok.\nKezdd el az elsőt a + gombbal!',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: workoutDays.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final day = workoutDays[index];
          return Card(
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(day.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(_formatDate(day.date),
                  style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: Icon(Icons.delete_forever, color: customRed),
                onPressed: () => _deleteWorkout(index),
                tooltip: 'Törlés',
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => WorkoutDetailScreen(
                    workoutDay: day,
                    onSave: (updatedWorkout) {
                      setState(() {
                        workoutDays[index] = updatedWorkout;
                        _saveWorkoutDays();
                      });
                    },
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}

// --- Edzésnap részletező képernyő ---

class WorkoutDetailScreen extends StatefulWidget {
  final WorkoutDay workoutDay;
  final ValueChanged<WorkoutDay> onSave;

  const WorkoutDetailScreen(
      {super.key, required this.workoutDay, required this.onSave});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
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
      _currentWorkout.exercises[exerciseIndex].sets
          .add(SetData(weight: weight, reps: reps));
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _currentWorkout.exercises[exerciseIndex].sets.removeAt(setIndex);
    });
  }

  void _addExercise() {
    final newExerciseNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Új gyakorlat hozzáadása'),
        content: TextField(
          controller: newExerciseNameController,
          decoration: const InputDecoration(hintText: 'Gyakorlat neve'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              final name = newExerciseNameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _currentWorkout.exercises
                      .add(Exercise(name: name, tip: ''));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Hozzáadás'),
          ),
        ],
      ),
    );
  }

  void _removeExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biztos törlöd a gyakorlatot?'),
        content:
        Text('A "${_currentWorkout.exercises[index].name}" gyakorlat törlésre kerül.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentWorkout.exercises.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }

  void _showAddSetDialog(int exerciseIndex) {
    final weightController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${_currentWorkout.exercises[exerciseIndex].name} - Új sorozat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Súly (kg)'),
            ),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ismétlés'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              final reps = int.tryParse(repsController.text);
              if (weight != null &&
                  weight > 0 &&
                  reps != null &&
                  reps > 0) {
                _addSet(exerciseIndex, weight, reps);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                      Text('Kérlek adj meg érvényes értékeket!')),
                );
              }
            },
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
  }

  void _saveWorkout() {
    widget.onSave(_currentWorkout);
    Navigator.pop(context);
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${_currentWorkout.name} - ${_formatDate(_currentWorkout.date)}'),
        backgroundColor: customRed,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: customRed),
            tooltip: 'Edzésnap mentése',
            onPressed: _saveWorkout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: customRed,
        onPressed: _addExercise,
        tooltip: 'Új gyakorlat hozzáadása',
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _currentWorkout.exercises.length,
        itemBuilder: (context, exIndex) {
          final exercise = _currentWorkout.exercises[exIndex];
          return Card(
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              title: Text(
                exercise.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: exercise.previousWeight != null
                  ? Text(
                'Előző súly: ${exercise.previousWeight!.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white70),
              )
                  : null,
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: customRed),
                tooltip: 'Gyakorlat törlése',
                onPressed: () => _removeExercise(exIndex),
              ),
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Tipp: ${exercise.tip}',
                    style: TextStyle(color: customRed),
                  ),
                ),
                const Divider(color: Colors.white12),
                ...exercise.sets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final set = entry.value;
                  return ListTile(
                    title: Text(
                      'Súly: ${set.weight.toStringAsFixed(1)} kg, Ismétlés: ${set.reps}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon:
                      Icon(Icons.delete_forever, color: customRed),
                      tooltip: 'Sorozat törlése',
                      onPressed: () => _removeSet(exIndex, setIndex),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Új sorozat hozzáadása',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => _showAddSetDialog(exIndex),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
