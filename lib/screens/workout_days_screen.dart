import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_day_screen.dart';

import '../theme.dart';
import '../models/workout_template.dart';
import '../services/workout_service.dart';
import 'workout_day_screen.dart';
import 'workout_detail_screen.dart';
import 'bmi_form.dart';

class WorkoutDaysScreen extends StatefulWidget {
  const WorkoutDaysScreen({super.key});

  @override
  State<WorkoutDaysScreen> createState() => _WorkoutDaysScreenState();
}

class _WorkoutDaysScreenState extends State<WorkoutDaysScreen> {
  List<WorkoutTemplate> workoutTemplates = [];
  String userName = '';
  final WorkoutService _workoutService = WorkoutService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeApp();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userName = prefs.getString('nickname') ?? 'Sportoló');
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    await _workoutService.createDefaultTemplates();
    await _loadWorkoutTemplates();
    setState(() => _isLoading = false);
  }

  Future<void> _loadWorkoutTemplates() async {
    final templates = await _workoutService.getTemplatesSortedByLastUsed();
    setState(() => workoutTemplates = templates);
  }

  Future<void> _startWorkout(WorkoutTemplate template) async {
    try {
      final session = await _workoutService.startWorkoutFromTemplate(template);
      // Léptessük először a nap szerkesztő képernyőre
      final customExercises = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDayScreen(session: session),
        ),
      );
      // Majd a részletező képernyőre a custom gyakorlatokkal
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(
            workoutSession: session,
            workoutService: _workoutService,
            customExercises: customExercises ?? [],
          ),
        ),
      );
      // Visszatérés után frissítjük a listát
      await _loadWorkoutTemplates();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba történt az edzés indításakor: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _createNewTemplate() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Új Edzéssablon 🏋️', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Sablon neve', hintText: 'Pl. MELL vagy HÁT'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Leírás (opcionális)', hintText: 'Pl. Mellkas és tricepsz edzés'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                });
              }
            },
            child: const Text('Létrehozás'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await _workoutService.createTemplate(
        name: result['name']!,
        description: result['description']!.isEmpty ? null : result['description'],
      );
      await _loadWorkoutTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Új sablon sikeresen létrehozva!'), backgroundColor: primaryPurple),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba a sablon létrehozásakor: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _deleteTemplate(WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sablon törlése'),
        content: Text('Biztos törlöd a "${template.name}" sablont?\n\nEz nem törli a korábbi edzésnapló bejegyzéseket.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _workoutService.deleteTemplate(template.id);
                await _loadWorkoutTemplates();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sablon törölve!'), backgroundColor: Colors.redAccent),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hiba a törléskor: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);
    if (difference.inDays == 0) return 'Ma';
    if (difference.inDays == 1) return 'Tegnap';
    if (difference.inDays < 7) return '${difference.inDays} napja';
    return '${lastUsed.year}.${lastUsed.month.toString().padLeft(2, '0')}.${lastUsed.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Helló, $userName! 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Melyik edzéssablonnal kezdünk?', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [IconButton(onPressed: _createNewTemplate, icon: const Icon(Icons.add, color: Colors.white))],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (_, idx) {
                final template = workoutTemplates[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(template.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (template.description?.isNotEmpty == true) Text(template.description!),
                        const SizedBox(height: 4),
                        Text(
                          '${template.exerciseTemplates.length} gyakorlat • Utoljára: ${_formatLastUsed(template.lastUsed)}',
                          style: const TextStyle(color: primaryPurple, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, color: Colors.redAccent), SizedBox(width: 8), Text('Törlés')]),
                        )
                      ],
                      onSelected: (value) {
                        if (value == 'delete') _deleteTemplate(template);
                      },
                    ),
                    onTap: () => _startWorkout(template),
                  ),
                );
              },
              childCount: workoutTemplates.length,
            ),
          ),
          if (workoutTemplates.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Még nincsenek edzéssablonok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Hozz létre egyet a + gombbal!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTemplate,
        backgroundColor: primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
