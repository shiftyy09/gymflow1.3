import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../models/workout_template.dart';
import '../services/workout_service.dart';
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
  final WorkoutService workoutService = WorkoutService();
  bool isLoading = true;
  bool _isInitialized = false; // Guard a duplikáció ellen

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeApp();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('nickname') ?? 'Sportoló';
    });
  }

  Future<void> _initializeApp() async {
    // Csak egyszer fusson le az inicializálás
    if (_isInitialized) return;
    _isInitialized = true;

    setState(() {
      isLoading = true;
    });

    // Alapértelmezett sablonok létrehozása (első indításkor)
    await workoutService.createDefaultTemplates();

    // Sablonok betöltése
    await _loadWorkoutTemplates();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadWorkoutTemplates() async {
    final templates = await workoutService.getTemplatesSortedByLastUsed();

    // Deduplikáljuk a sablonokat ID alapján
    final uniqueTemplates = <String, WorkoutTemplate>{};
    for (var template in templates) {
      uniqueTemplates[template.id] = template;
    }

    setState(() {
      workoutTemplates = uniqueTemplates.values.toList();
    });
  }

  Future<void> startWorkout(WorkoutTemplate template) async {
    try {
      // Új edzés indítása a sablonból
      final session = await workoutService.startWorkoutFromTemplate(template);

      // Navigálás az edzés részleteihez
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDetailScreen(
            workoutSession: session,
            workoutService: workoutService,
          ),
        ),
      );

      // Ha visszatértünk, frissítjük a sablonokat
      if (result == true) {
        await _loadWorkoutTemplates();
      }
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
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Új Edzéssablon',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Pl. MELL vagy HÁT',
                  labelText: 'Sablon neve',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Pl. Mellkas és tricepsz edzés',
                  labelText: 'Leírás (opcionális)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégse'),
          ),
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
      await workoutService.createTemplate(
        name: result['name']!,
        description: result['description']!.isEmpty ? null : result['description'],
      );
      await _loadWorkoutTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Új sablon sikeresen létrehozva!'),
          backgroundColor: primaryPurple,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba a sablon létrehozásakor: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _deleteTemplate(WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sablon törlése'),
        content: Text(
          'Biztos törlöd a "${template.name}" sablont?\n(Ez nem törli a korábbi edzésnaplió bejegyzéseket.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await workoutService.deleteTemplate(template.id);
                await _loadWorkoutTemplates();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sablon törölve!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hiba a törlésnél: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
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

    if (difference.inDays == 0) {
      return 'Ma';
    } else if (difference.inDays == 1) {
      return 'Tegnap';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} napja';
    } else {
      return '${lastUsed.year}.${lastUsed.month.toString().padLeft(2, '0')}.${lastUsed.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryPurple),
        ),
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
                        Text(
                          'Helló, $userName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Melyik edzéssablonnal kezdünk?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _createNewTemplate,
                icon: const Icon(Icons.add),
                color: Colors.white,
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                final template = workoutTemplates[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (template.description?.isNotEmpty == true)
                          Text(template.description!),
                        const SizedBox(height: 4),
                        Text(
                          '${template.exerciseTemplates.length} gyakorlat • Utoljára: ${_formatLastUsed(template.lastUsed)}',
                          style: const TextStyle(
                            color: primaryPurple,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Törlés'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteTemplate(template);
                        }
                      },
                    ),
                    onTap: () => startWorkout(template),
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
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Még nincsenek edzéssablonok',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hozz létre egyet a + gombbal!',
                        style: TextStyle(color: Colors.grey),
                      ),
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