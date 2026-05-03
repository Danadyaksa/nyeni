import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show routeObserver;
import '../../controllers/event_controller.dart';
import '../../services/shake_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen_new.dart';
import 'map_screen.dart';
import 'games_screen.dart';
import 'bagas_screen.dart';
import 'event_detail_screen.dart';
import '../widgets/more_menu_sheet.dart';
import '../widgets/user/shake_intro_overlay.dart';
import '../widgets/user/shake_event_popup.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with RouteAware {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const ProfileScreen(),
    const MapScreen(),
    HomeScreen(),
    const GamesScreen(),
    const SizedBox(),
  ];

  final _shakeService = ShakeService();
  final _eventController = EventController();
  List<dynamic> _allEvents = [];
  bool _shakePopupShowing = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _shakeService.start(_onShake);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _shakeService.stop();
    super.dispose();
  }

  @override
  void didPushNext() {
    _shakeService.stop();
  }

  @override
  void didPopNext() {
    _shakeService.start(_onShake);
  }

  Future<void> _loadEvents() async {
    final events = await _eventController.getAllEvents();
    if (mounted) {
      setState(() => _allEvents = events
          .map((e) => {
                'id': e.id,
                'title': e.name,
                'category': e.category,
                'event_date': e.date,
                'location': e.location,
                'price': e.price,
                'image_url': e.imageUrl ?? '',
              })
          .toList());
    }
  }

  // ─── Shake Handler ───────────────────────────────────────────────────────

  void _onShake() {
    if (!mounted || _shakePopupShowing || _allEvents.isEmpty) return;
    final event = _allEvents[Random().nextInt(_allEvents.length)];
    _showShakeIntro(event);
  }

  void _showShakeIntro(Map<String, dynamic> event) {
    _shakePopupShowing = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'shake_intro',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      pageBuilder: (ctx, _, __) => ShakeIntroOverlay(
        onDone: () {
          Navigator.pop(ctx);
          _showShakePopup(event);
        },
      ),
    );
  }

  void _showShakePopup(Map<String, dynamic> event) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'shake_popup',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => ShakeEventPopup(
        event: event,
        onViewDetail: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: event['id'] as int),
            ),
          );
        },
        onDismiss: () => Navigator.pop(ctx),
        onShuffle: () {
          Navigator.pop(ctx);
          Future.delayed(const Duration(milliseconds: 200), () {
            if (_allEvents.isNotEmpty) {
              final next = _allEvents[Random().nextInt(_allEvents.length)];
              _showShakePopup(next);
            }
          });
        },
      ),
    ).then((_) => _shakePopupShowing = false);
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _onItemTapped(int index) async {
    if (index == 4) {
      MoreMenuSheet.show(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if ((index == 0 || index == 3) && token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamu harus login dulu untuk membuka fitur ini!'),
            backgroundColor: Color(0xFF2C3E50),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab_bagas',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BagasScreen()),
          );
        },
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.bot, color: Colors.white, size: 28),
      ),
      body: IndexedStack(
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
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.user), label: 'Profil'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.mapPin), label: 'Lokasi'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.gamepad2), label: 'Games'),
            BottomNavigationBarItem(
                icon: Icon(LucideIcons.menu), label: 'Lainnya'),
          ],
        ),
      ),
    );
  }
}
