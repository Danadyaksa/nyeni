import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. TAMBAHKAN IMPORT INI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('nyeni_box'); 
  await Hive.openBox('bagas_chats'); 

  // Tidak perlu cek token di sini lagi karena sudah di-handle di MainNavigation
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
      // Langsung arahkan ke MainNavigation
      home: const MainNavigation(), 
    );
  }
}