import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'workout_days_screen.dart';

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
      _recommendedProtein = savedProtein;
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
    if (_nicknameController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      _showSnackBar('Adj meg becenevet, testsúlyt és magasságot!');
      return;
    }
    final weight = double.tryParse(_weightController.text);
    final heightCm = double.tryParse(_heightController.text);
    if (weight == null || heightCm == null || weight <= 0 || heightCm <= 0) {
      _showSnackBar('Kérlek adj meg érvényes számokat!');
      return;
    }
    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);
    String motivation;
    switch (_selectedLevel) {
      case 'Kezdő':
        motivation = "${_nicknameController.text}, minden nagy út egy lépéssel kezdődik!";
        break;
      case 'Haladó':
        motivation = "${_nicknameController.text}, szuper munka eddig!";
        break;
      default:
        motivation = "${_nicknameController.text}, tisztelet!";
    }
    final protein = double.parse((weight * 1.8).toStringAsFixed(1));
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
        MaterialPageRoute(builder: (_) => const WorkoutDaysScreen()),
      );
    } else {
      _showSnackBar('Előbb számold ki a BMI-t!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryPurple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profil beállítások'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField('Becenév', _nicknameController, 'Pl. Fitness Rajongó'),
              _buildInputField('Testsúly (kg)', _weightController, '70', keyboardType: TextInputType.number),
              _buildInputField('Magasság (cm)', _heightController, '175', keyboardType: TextInputType.number),
              _buildLevelSelector(),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _calculateBMI, child: const Text('BMI Számítás 📊')),
              const SizedBox(height: 30),
              if (_showResult) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildLevelSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Milyen szinten vagy?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Row(children: _levels.map((level) {
        final isSelected = _selectedLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedLevel = level),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? accentPink : Colors.white.withOpacity(0.15),
              ),
              child: Text(level, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            ),
          ),
        );
      }).toList()),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildResultCard() {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('BMI: $_bmi', style: const TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 20),
          Text(_motivation, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          if (_recommendedProtein != null) Text('Ajánlott napi fehérjebevitel: $_recommendedProtein g', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _goToWorkoutDays, child: const Text('Kezdjük az edzést! 🚀')),
        ]),
      ),
    );
  }
}
