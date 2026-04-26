import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login_screen.dart'; // Import halaman login
import 'home_screen.dart'; // Import halaman home
import 'profile_screen.dart';
import 'map_screen.dart';
import 'games_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // Default ke Home

  final List<Widget> _pages = [
    const ProfileScreen(), // Index 0
    const MapScreen(), // Index 1
    HomeScreen(), // Index 2
    const GamesScreen(), // Index 3
    const Center(child: Text('Halaman Menu Lainnya')), // Index 4
  ];

  void _onItemTapped(int index) {
    // 1. Buka brankas lokal kita
    final box = Hive.box('nyeni_box');
    
    // 2. Cek status user. Kalau kosong, anggap saja dia 'guest' (tamu)
    final role = box.get('role', defaultValue: 'guest');

    // 3. Logika Cegatan! (Index 0 = Profil, Index 3 = Games)
    if ((index == 0 || index == 3) && role == 'guest') {
      // Munculkan peringatan kecil (SnackBar)
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
      return; // Hentikan fungsi di sini, jangan pindah tab di bawah
    }

    // Kalau aman (sudah login atau klik menu yang tidak dikunci), pindah tab
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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