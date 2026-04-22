// Path: lib/presentation/screens/auth/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../services/auth_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _Colors {
  static const deepForest = Color(0xFF071A14);
  static const forestMid = Color(0xFF0E4D32);
  static const forestLight = Color(0xFF1A5C40);
  static const gold = Color(0xFFC4973A);
  static const goldDim = Color(0x99C4973A);
  static const goldFaint = Color(0x22C4973A);
  static const parchment = Color(0xFFF0E6C8);
  static const parchmentDim = Color(0xCCF0E6C8);
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _rotateController;
  late AnimationController _glowController;

  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _slideUp;
  late Animation<double> _ringRotation;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Entrance animation (staggered reveal)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Continuous slow ring rotation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 22),
      vsync: this,
    )..repeat();

    _ringRotation =
        Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_rotateController);

    // Glow pulse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authServiceProvider);
    context.go(auth.isAuthenticated ? '/student/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.deepForest,
      body: Stack(
        children: [
          // ── Background geometric pattern ──
          const Positioned.fill(
            child: _IslamicBackgroundPainter(),
          ),

          // ── Radial ambient glow ──
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (_, __) => Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.75,
                    colors: [
                      _Colors.forestLight.withOpacity(0.35 * _glowPulse.value),
                      _Colors.deepForest.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SizedBox(
              width: double
                  .infinity, // 👈 هذا السطر هو الحل! يجبر المحتوى على التمركز
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (_, __) => Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // 👈 تأكيد التمركز
                  children: [
                    const Spacer(flex: 2),

                    // Bismillah inscription
                    Opacity(
                      opacity: _fadeIn.value,
                      child: const Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          color: _Colors.goldDim,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Rotating ring + logo
                    ScaleTransition(
                      scale: _scaleUp,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: _AnimatedLogoRing(
                          rotation: _ringRotation,
                          glowPulse: _glowPulse,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // App title + subtitle
                    Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Column(
                          children: [
                            const Text(
                              'مركز الفرقان',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _Colors.parchment,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Gold divider
                            SizedBox(
                              width: 80,
                              child: CustomPaint(
                                painter: _GoldDividerPainter(),
                                size: const Size(80, 8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _Colors.gold.withOpacity(0.25)),
                                borderRadius: BorderRadius.circular(30),
                                color: _Colors.goldFaint,
                              ),
                              child: const Text(
                                'لتعليم وتحفيظ القرآن الكريم',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: _Colors.goldDim,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Loading dots
                    Opacity(
                      opacity: _fadeIn.value,
                      child: const _GoldDotsLoader(),
                    ),

                    const Spacer(),

                    // Version
                    Opacity(
                      opacity: _fadeIn.value * 0.45,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 28),
                        child: Text(
                          'الإصدار  1.0.1',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated logo ring ────────────────────────────────────────────────────────
class _AnimatedLogoRing extends StatelessWidget {
  final Animation<double> rotation;
  final Animation<double> glowPulse;

  const _AnimatedLogoRing({
    required this.rotation,
    required this.glowPulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotation, glowPulse]),
      builder: (_, __) => SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring (pulsing)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _Colors.gold.withOpacity(0.18 * glowPulse.value),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            // Rotating 8-point star ring
            Transform.rotate(
              angle: rotation.value,
              child: CustomPaint(
                painter: _StarRingPainter(),
                size: const Size(140, 140),
              ),
            ),
            // Inner logo circle
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [_Colors.forestLight, _Colors.deepForest],
                  center: Alignment(-0.3, -0.3),
                ),
                border: Border.all(
                  color: _Colors.gold.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _Colors.deepForest,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_book_rounded,
                    size: 40,
                    color: _Colors.gold,
                  ),
                ),
              ),
            ),
            // Gold dot accent on top
            Positioned(
              top: 10,
              right: 30,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Colors.gold.withOpacity(glowPulse.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────
class _IslamicBackgroundPainter extends StatelessWidget {
  const _IslamicBackgroundPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _IslamicBgPainter());
  }
}

class _IslamicBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0FC4973A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw 8-point stars at corners and center
    final positions = [
      Offset(-size.width * 0.15, size.height * 0.15),
      Offset(size.width * 1.1, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.42),
      Offset(-size.width * 0.05, size.height * 0.78),
      Offset(size.width * 1.05, size.height * 0.85),
    ];
    final radii = [180.0, 120.0, 80.0, 140.0, 90.0];

    for (var i = 0; i < positions.length; i++) {
      _drawEightPointStar(canvas, positions[i], radii[i], paint);
    }

    // Delicate corner filigree lines
    final linePaint = Paint()
      ..color = const Color(0x18C4973A)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Top-right corner
    canvas.drawLine(
        Offset(size.width - 20, 30), Offset(size.width - 70, 30), linePaint);
    canvas.drawLine(
        Offset(size.width - 20, 30), Offset(size.width - 20, 80), linePaint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(20, size.height - 30), Offset(70, size.height - 30), linePaint);
    canvas.drawLine(
        Offset(20, size.height - 30), Offset(20, size.height - 80), linePaint);

    // Bottom arch ornament
    final archPaint = Paint()
      ..color = const Color(0x30C4973A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final archPath = Path()
      ..moveTo(size.width * 0.2, size.height - 60)
      ..quadraticBezierTo(size.width * 0.5, size.height - 100, size.width * 0.8,
          size.height - 60);
    canvas.drawPath(archPath, archPaint);

    final archPath2 = Path()
      ..moveTo(size.width * 0.3, size.height - 48)
      ..quadraticBezierTo(size.width * 0.5, size.height - 76, size.width * 0.7,
          size.height - 48);
    canvas.drawPath(archPath2, archPaint..color = const Color(0x20C4973A));
  }

  void _drawEightPointStar(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);
      final innerAngle1 = angle - 0.22;
      final innerAngle2 = angle + 0.22;
      final innerR = radius * 0.42;

      if (i == 0) path.moveTo(center.dx, center.dy);
      path
        ..lineTo(center.dx + innerR * math.cos(innerAngle1),
            center.dy + innerR * math.sin(innerAngle1))
        ..lineTo(outerX, outerY)
        ..lineTo(center.dx + innerR * math.cos(innerAngle2),
            center.dy + innerR * math.sin(innerAngle2));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StarRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;

    // Outer dashed circle
    final dashPaint = Paint()
      ..color = const Color(0x55C4973A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), outerR - 2, dashPaint);

    // 8 gold dots on the ring
    final dotPaint = Paint()..color = const Color(0xFFC4973A);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = cx + (outerR - 6) * math.cos(angle);
      final y = cy + (outerR - 6) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }

    // Inner circle
    final innerPaint = Paint()
      ..color = const Color(0x33C4973A)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), outerR * 0.65, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GoldDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Gradient-like fade (left side)
    paint.color = const Color(0x00C4973A);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(cx * 0.3, size.height / 2), paint);
    paint.color = const Color(0xFFC4973A);
    canvas.drawLine(Offset(cx * 0.3, size.height / 2),
        Offset(cx - 6, size.height / 2), paint);

    // Center diamond
    final dPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + 5, size.height / 2)
      ..lineTo(cx, size.height)
      ..lineTo(cx - 5, size.height / 2)
      ..close();
    canvas.drawPath(dPath, Paint()..color = const Color(0xFFC4973A));

    // Right side
    paint.color = const Color(0xFFC4973A);
    canvas.drawLine(Offset(cx + 6, size.height / 2),
        Offset(cx * 1.7, size.height / 2), paint);
    paint.color = const Color(0x00C4973A);
    canvas.drawLine(Offset(cx * 1.7, size.height / 2),
        Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Animated gold dots loader ─────────────────────────────────────────────────
class _GoldDotsLoader extends StatefulWidget {
  const _GoldDotsLoader();

  @override
  State<_GoldDotsLoader> createState() => _GoldDotsLoaderState();
}

class _GoldDotsLoaderState extends State<_GoldDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final scale = (math.sin(t * math.pi)).clamp(0.3, 1.0);
          final opacity = 0.3 + 0.7 * scale;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.6 + 0.4 * scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Colors.gold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
