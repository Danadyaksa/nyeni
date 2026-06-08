import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart' show routeObserver;
import '../../controllers/event_controller.dart';
import '../../services/shake_service.dart';
import '../../config/api_config.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'games_screen.dart';
import 'bagas_screen.dart';
import 'event_detail_screen.dart';
import '../widgets/more_menu_sheet.dart';
import '../widgets/user/shake_intro_overlay.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with RouteAware {  // subscribe ke RouteObserver
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
    // Subscribe ke routeObserver setelah context tersedia
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _shakeService.stop();
    super.dispose();
  }

  // Dipanggil saat route lain di-push di atas MainNavigation → pause shake
  @override
  void didPushNext() {
    _shakeService.stop();
  }

  // Dipanggil saat kembali ke MainNavigation → resume shake
  @override
  void didPopNext() {
    _shakeService.start(_onShake);
  }

  Future<void> _loadEvents() async {
    final events = await _eventController.getAllEvents();
    if (mounted) {
      // Convert Event models to Map for compatibility
      setState(() => _allEvents = events.map((e) => {
        'id': e.id,
        'title': e.name,
        'category': e.category,
        'event_date': e.date,
        'location': e.location,
        'price': e.price,
        'image_url': e.imageUrl ?? '',
      }).toList());
    }
  }

  // ─── Shake handler ────────────────────────────────────────────────────────

  void _onShake() {
    if (!mounted || _shakePopupShowing || _allEvents.isEmpty) return;
    // Pilih event random
    final event = _allEvents[Random().nextInt(_allEvents.length)];
    _showShakeIntro(event);
  }

  // ─── Step 1: Intro animasi "Shake Detected!" ──────────────────────────────

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

  // ─── Step 2: Card rekomendasi ─────────────────────────────────────────────

  void _showShakePopup(Map<String, dynamic> event) {
    final price = event['price'] ?? 0;
    final priceStr = price == 0
        ? 'Gratis'
        : 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

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
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gambar event ──
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Stack(
                    children: [
                        Image.network(
                        ApiConfig.normalizeImageUrl(event['image_url']?.toString() ?? ''),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: const Color(0xFF9A3412),
                          child: const Icon(LucideIcons.image, color: Colors.white54, size: 48),
                        ),
                      ),
                      // Overlay gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badge shake
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.zap, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Shake Detected!',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      // Kategori badge
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event['category']?.toString() ?? '',
                            style: GoogleFonts.manrope(
                                color: const Color(0xFF9A3412),
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Konten ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label rekomendasi
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Rekomendasi Untukmu',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Judul event
                      Text(
                        event['title']?.toString() ?? '-',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3A302A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info tanggal & lokasi
                      _infoRow(LucideIcons.calendar, event['event_date']?.toString() ?? '-'),
                      const SizedBox(height: 6),
                      _infoRow(LucideIcons.mapPin, event['location']?.toString() ?? '-'),
                      const SizedBox(height: 16),

                      // Harga
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9A3412).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              priceStr,
                              style: GoogleFonts.ebGaramond(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF9A3412),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Tombol acak lagi
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (_allEvents.isNotEmpty) {
                                  final next = _allEvents[Random().nextInt(_allEvents.length)];
                                  _showShakePopup(next);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.shuffle, size: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tombol lihat event
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(
                                    eventId: event['id'] as int),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9A3412),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lihat Event',
                                  style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.arrowRight,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tombol tutup
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Tutup',
                              style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => _shakePopupShowing = false);
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF78706A)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(color: const Color(0xFF78706A), fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

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
          SnackBar(
            content: Text('Kamu harus login dulu untuk membuka fitur ini!', style: GoogleFonts.manrope()),
            backgroundColor: const Color(0xFF9A3412),
            duration: const Duration(seconds: 2),
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
        backgroundColor: const Color(0xFF9A3412),
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
          selectedItemColor: const Color(0xFF9A3412),
          unselectedItemColor: const Color(0xFF78706A).withOpacity(0.6),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              GoogleFonts.manrope(fontWeight: FontWeight.normal, fontSize: 12),
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
