import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'views/user/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';

// RouteObserver global — dipakai MainNavigation untuk pause/resume shake
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('nyeni_box');
  await Hive.openBox('bagas_chats');
  await Hive.openBox('notifications');

  await NotificationService().init();

  runApp(const NyeniApp());
}

class NyeniApp extends StatelessWidget {
  const NyeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyeni',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver], // daftarkan observer
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C3E50)),
        textTheme: GoogleFonts.outfitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const SplashScreen(), // Ganti ke SplashScreen untuk cek session
    );
  }
}