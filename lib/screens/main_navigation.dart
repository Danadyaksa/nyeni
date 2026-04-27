import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'games_screen.dart';
import 'bagas_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // Default ke Home

  final List<Widget> _pages = [
    const ProfileScreen(), // Index 0
    const MapScreen(),     // Index 1
    HomeScreen(),    // Index 2 (Pastikan HomeScreen sudah const/clean dari Supabase)
    const GamesScreen(),   // Index 3
    const Center(child: Text('Halaman Menu Lainnya')), // Index 4
  ];

  // Fungsi ini sekarang async karena perlu cek SharedPreferences
  void _onItemTapped(int index) async {
    // 1. Cek token di SharedPreferences (Sistem Baru)
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    // 2. Logika Cegatan untuk Profil (0) dan Games (3)
    if ((index == 0 || index == 3) && token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamu harus login dulu untuk membuka fitur ini!'),
            backgroundColor: Color(0xFF2C3E50),
            duration: Duration(seconds: 2),
          ),
        );

        // Lempar ke halaman Login
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return; 
    }

    // Kalau sudah login atau klik menu yang tidak dikunci (Home/Lokasi)
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HERO ERROR FIX: Tambahkan heroTag unik di sini
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab_bagas', // Mencegah error multiple heroes
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BagasScreen()),
          );
        },
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.bot, color: Colors.white, size: 28),
      ),
      body: IndexedStack( // Menggunakan IndexedStack agar state halaman tidak hilang saat pindah tab
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2C3E50),
          unselectedItemColor: Colors.grey.shade400,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profil'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.mapPin), label: 'Lokasi'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.gamepad2), label: 'Games'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.menu), label: 'Lainnya'),
          ],
        ),
      ),
    );
  }
}