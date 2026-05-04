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
      pageBuilder: (ctx, _, __) => _ShakeIntroOverlay(
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

// ─── Intro overlay "Shake Detected!" ─────────────────────────────────────────

class _ShakeIntroOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _ShakeIntroOverlay({required this.onDone});

  @override
  State<_ShakeIntroOverlay> createState() => _ShakeIntroOverlayState();
}

class _ShakeIntroOverlayState extends State<_ShakeIntroOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;   // kontrol keseluruhan (fade in → hold → fade out)
  late AnimationController _rippleCtrl; // ripple melebar terus
  late AnimationController _iconCtrl;   // ikon goyang kiri-kanan

  late Animation<double> _bgFade;
  late Animation<double> _contentFade;
  late Animation<double> _contentScale;
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;
  late Animation<double> _iconShake;

  @override
  void initState() {
    super.initState();

    // ── Main controller: 1.2 detik total ──
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bgFade = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_mainCtrl);

    _contentFade = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_mainCtrl);

    _contentScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 10),
      TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
    ]).animate(_mainCtrl);

    // ── Ripple controller: loop terus ──
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _ripple1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
    _ripple2 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Icon shake controller: goyang 3x ──
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _iconShake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));

    // Mulai semua animasi
    _mainCtrl.forward().then((_) => widget.onDone());
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _iconCtrl.forward();
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _rippleCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _rippleCtrl, _iconCtrl]),
      builder: (_, __) {
        return Opacity(
          opacity: _bgFade.value,
          child: Container(
            color: const Color(0xFF0D1B2A),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Ripple lingkaran melebar ──
                _buildRipple(_ripple1.value, 0.35),
                _buildRipple(_ripple2.value, 0.20),

                // ── Konten utama ──
                Opacity(
                  opacity: _contentFade.value,
                  child: Transform.scale(
                    scale: _contentScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon goyang
                        Transform.translate(
                          offset: Offset(_iconShake.value, 0),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.3),
                                  Colors.orange.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.6),
                                  width: 1.5),
                            ),
                            child: const Icon(
                              LucideIcons.smartphone,
                              color: Colors.orange,
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Teks utama
                        const Text(
                          'SHAKE DETECTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Garis dekoratif
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 1.5,
                              color: Colors.orange.withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 30,
                              height: 1.5,
                              color: Colors.orange.withOpacity(0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Teks bawah
                        const Text(
                          'Mencari rekomendasi event untukmu',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRipple(double progress, double maxOpacity) {
    final size = MediaQuery.of(context).size;
    final maxRadius = size.width * 0.7;
    return Opacity(
      opacity: (maxOpacity * (1 - progress)).clamp(0.0, 1.0),
      child: Container(
        width: maxRadius * progress * 2,
        height: maxRadius * progress * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.orange,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
