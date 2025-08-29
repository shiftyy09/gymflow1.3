import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'bmi_form.dart';
import 'workout_days_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  bool _showLogo = false;
  bool _showForm = false;
  bool _checkingUserData = false;

  late final AnimationController _animationController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showLogo = true);

    await Future.delayed(const Duration(milliseconds: 2500));
    setState(() => _showLogo = false);

    await Future.delayed(const Duration(milliseconds: 300));
    await _checkUserData();
  }

  Future<void> _checkUserData() async {
    setState(() => _checkingUserData = true);
    final prefs = await SharedPreferences.getInstance();
    final hasBmi = prefs.getDouble('bmi') != null;
    final hasNickname = prefs.getString('nickname')?.isNotEmpty == true;

    if (hasBmi && hasNickname) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WorkoutDaysScreen()),
      );
    } else {
      setState(() {
        _checkingUserData = false;
        _showForm = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            if (!_showForm && !_checkingUserData)
              Center(
                child: AnimatedOpacity(
                  opacity: _showLogo ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.white.withOpacity(0.8)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(Icons.fitness_center, size: 60, color: primaryPurple),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'GYMFLOW',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Fitness Reimagined',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_checkingUserData)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            if (_showForm) const BmiForm(),
          ],
        ),
      ),
    );
  }
}
