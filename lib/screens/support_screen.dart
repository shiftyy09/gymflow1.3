import 'package:flutter/material.dart';
import '../theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Támogatás'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightGray, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kapcsolat kártya
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: primaryPurple,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Kapcsolat',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kérdésed van vagy segítségre van szükséged?',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildContactItem(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: 'support@gymflow.app',
                      ),
                      _buildContactItem(
                        icon: Icons.bug_report,
                        title: 'Hiba bejelentés',
                        subtitle: 'Találtál hibát? Szólj nekünk!',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // App info kártya
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryPurple,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Alkalmazás információ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem('Verzió', 'GymFlow v1.3'),
                      _buildInfoItem('Fejlesztő', 'Archi Development'),
                      _buildInfoItem('Kiadás dátuma', 'September 2025'),
                      _buildInfoItem('Platform', 'Flutter/Dart'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Funkciók kártya
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_outline,
                            color: primaryPurple,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Főbb funkciók',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem('🏋️', 'Edzés tervezés és követés'),
                      _buildFeatureItem('📊', 'BMI számológép'),
                      _buildFeatureItem('📱', 'Egyszerű, intuitív kezelés'),
                      _buildFeatureItem('💪', 'Személyre szabott edzéstervek'),
                      _buildFeatureItem('📈', 'Fejlődés nyomon követése'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Köszönjük, hogy használod a GymFlow-t!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '💪 Edzz okosan, éld egészségesen! 💪',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}