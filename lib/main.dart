import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Ganti URL dan Anon Key ini dengan yang ada di dashboard Supabase kamu nanti
const supabaseUrl = 'https://yanzprnzegpffmfcspkp.supabase.co';
const supabaseKey = 'sb_publishable_MP7-jhjcwXtwcuqnHOUA0g_Swrqpm2P';

void main() async {
  // Wajib dipanggil kalau kita butuh inisialisasi sesuatu sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Supabase (Cloud Database)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // 2. Inisialisasi Hive (Local Storage)
  await Hive.initFlutter();
  // Kita bikin satu 'kotak' lokal bernama 'nyeni_box' buat nyimpen sesi & cache
  await Hive.openBox('nyeni_box'); 

  runApp(const NyeniApp());
}

class NyeniApp extends StatelessWidget {
  const NyeniApp({super.key});

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
      // Untuk sementara kita arahkan home-nya ke LoginScreen yang bakal kita buat
      home: const MainNavigation(), 
    );
  }
}