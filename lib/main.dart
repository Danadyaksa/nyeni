import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const supabaseUrl = 'https://yanzprnzegpffmfcspkp.supabase.co';
const supabaseKey = 'sb_publishable_MP7-jhjcwXtwcuqnHOUA0g_Swrqpm2P';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  
  // 2. Inisialisasi Hive
  await Hive.initFlutter();
  
  // Buka box untuk sesi/cache umum
  await Hive.openBox('nyeni_box'); 
  // BUKA BOX KHUSUS BAGAS (Sangat Penting!)
  await Hive.openBox('bagas_chats'); 

  // Cek apakah ada session Supabase yang masih aktif
  final session = Supabase.instance.client.auth.currentSession;

  runApp(NyeniApp(isLoggedIn: session != null));
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
      // Gunakan logika isLoggedIn supaya tidak perlu login ulang
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(), 
    );
  }
}