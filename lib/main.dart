import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  // 1. Inisialisasi binding Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Hive (Untuk fitur Chat/Bagas kamu)
  await Hive.initFlutter();
  await Hive.openBox('nyeni_box'); 
  await Hive.openBox('bagas_chats'); 

  // 3. Cek apakah ada session login lokal (SharedPreferences)
  // Ini pengganti logic: Supabase.instance.client.auth.currentSession
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  // Jika token tidak null, berarti user sudah login
  runApp(NyeniApp(isLoggedIn: token != null));
}

class NyeniApp extends StatelessWidget {
  final bool isLoggedIn;
  const NyeniApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyeni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C3E50)), 
        textTheme: GoogleFonts.outfitTextTheme(), 
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      // Jika isLoggedIn true langsung ke MainNavigation, jika tidak ke LoginScreen
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(), 
    );
  }
}