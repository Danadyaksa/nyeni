import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'trivia_screen.dart'; // Import game kuis
import 'gyro_game_screen.dart'; // Import game bola

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Pusat Permainan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Pilih Permainan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
            const SizedBox(height: 8),
            const Text('Mainkan game edukasi ini untuk mengumpulkan XP dan menaikkan level akunmu!', style: TextStyle(color: Colors.grey, height: 1.5)),
            const SizedBox(height: 32),
            
            // 1. Kartu Nyeni Trivia (Dibungkus Expanded biar ngisi layar)
            Expanded(
              child: _buildBigGameCard(
                context,
                title: 'Nyeni Trivia',
                subtitle: 'Uji wawasan seni dan budayamu dengan 50 pertanyaan menantang yang penuh edukasi.',
                icon: LucideIcons.brainCircuit,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TriviaScreen()));
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Kartu Nyeni Labyrinth (Dibungkus Expanded biar ngisi layar)
            Expanded(
              child: _buildBigGameCard(
                context,
                title: 'Nyeni Labyrinth',
                subtitle: 'Uji keseimbangan tanganmu! Miringkan HP perlahan untuk mengarahkan bola ke tujuan.',
                icon: LucideIcons.smartphone,
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GyroGameScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigGameCard(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color iconColor, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16), // Padding sedikit dikecilkan agar aman di HP kecil
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        // Tambahkan Center dan SingleChildScrollView di sini
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Scroll halus jika layarnya mentok
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(icon, size: 48, color: iconColor), // Ukuran ikon disesuaikan sedikit
                ),
                const SizedBox(height: 16),
                Text(
                  title, 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}