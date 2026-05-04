import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay animasi "Shake Detected!" yang muncul setelah shake
class ShakeIntroOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const ShakeIntroOverlay({
    super.key,
    required this.onDone,
  });

  @override
  State<ShakeIntroOverlay> createState() => _ShakeIntroOverlayState();
}

class _ShakeIntroOverlayState extends State<ShakeIntroOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _iconCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _contentFade;
  late Animation<double> _contentScale;
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;
  late Animation<double> _iconShake;

  @override
  void initState() {
    super.initState();

    // Main controller: 1.2 detik total
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

    // Ripple controller: loop terus
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

    // Icon shake controller: goyang 3x
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
            color: const Color(0xFF3A302A),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple lingkaran melebar
                _buildRipple(_ripple1.value, 0.35),
                _buildRipple(_ripple2.value, 0.20),

                // Konten utama
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
                                  const Color(0xFF9A3412).withOpacity(0.3),
                                  const Color(0xFF9A3412).withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                  color: const Color(0xFF9A3412).withOpacity(0.6),
                                  width: 1.5),
                            ),
                            child: const Icon(
                              LucideIcons.smartphone,
                              color: Color(0xFF9A3412),
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Teks utama
                        Text(
                          'SHAKE DETECTED',
                          style: GoogleFonts.manrope(
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
                              color: const Color(0xFF9A3412).withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9A3412),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 30,
                              height: 1.5,
                              color: const Color(0xFF9A3412).withOpacity(0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Teks bawah
                        Text(
                          'Memunculkan event random untukmu',
                          style: GoogleFonts.manrope(
                            color: Colors.white70,
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
            color: const Color(0xFF9A3412),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
