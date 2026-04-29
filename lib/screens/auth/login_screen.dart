// Path: lib/presentation/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

// ─── Design Tokens (reuse from splash or place in a shared tokens file) ───────
class _C {
  static const deepForest = Color(0xFF071A14);
  static const forestMid = Color(0xFF0E4D32);
  static const forestLight = Color(0xFF1A5C40);
  static const gold = Color(0xFFC4973A);
  static const goldDim = Color(0x99C4973A);
  static const goldFaint = Color(0x18C4973A);
  static const goldBorder = Color(0x33C4973A);
  static const parchment = Color(0xFFF0E6C8);
  static const cardBg = Color(0xFF0C1E16);
  static const inputBg = Color(0xFF0A1810);
  static const error = Color(0xFFE06060);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass = true;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = ref.read(authServiceProvider.notifier);
    final ok = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (ok && mounted) context.go('/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);

    return Directionality(
      // ── Force RTL for the entire login screen ──
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.deepForest,
        body: Stack(
          children: [
            // ── Background geometric decoration ──
            const Positioned.fill(child: _LoginBgPainter()),

            // ── Scrollable content: Positioned.fill forces full-width inside Stack ──
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // stretch = full width
                  children: [
                    // ── Header ──────────────────────────────────────────────────
                    _Header(),

                    // ── Login Card (overlaps header) ─────────────────────────────
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _LoginCard(
                          formKey: _formKey,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          obscurePass: _obscurePass,
                          isLoading: authState.isLoading,
                          error: authState.error,
                          shimmer: _shimmer,
                          onTogglePass: () =>
                              setState(() => _obscurePass = !_obscurePass),
                          onLogin: authState.isLoading ? null : _login,
                          onRegister: () => context.go('/register'),
                          onForgot: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'ميزة استعادة كلمة المرور قريباً',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                              backgroundColor: _C.forestMid,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: _C.goldBorder),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Bottom ornament ──────────────────────────────────────────
                    const _BottomOrnament(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ), // Positioned.fill
          ],
        ),
      ), // Directionality
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 72, bottom: 46),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E5A38), Color(0xFF0B3828), Color(0xFF071A14)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(44),
          bottomRight: Radius.circular(44),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background star decoration
          Positioned(
            top: -20,
            right: -20,
            child: CustomPaint(
              painter: _FaintStarPainter(radius: 120, opacity: 0.06),
              size: const Size(160, 160),
            ),
          ),

          // Corner filigree lines
          Positioned(
            top: 0,
            left: 20,
            child: CustomPaint(
              painter: _FiligreeCornerPainter(flip: false),
              size: const Size(40, 40),
            ),
          ),
          Positioned(
            top: 0,
            right: 20,
            child: CustomPaint(
              painter: _FiligreeCornerPainter(flip: true),
              size: const Size(40, 40),
            ),
          ),

          // Center content — must be full-width so children can center properly
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1A5C40), Color(0xFF0D3826)],
                    ),
                    border: Border.all(color: _C.goldBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _C.gold.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        size: 36,
                        color: _C.gold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'أهلاً بك يا طالب العِلم',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _C.parchment,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'سجّل دخولك لمتابعة مسيرتك القرآنية',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: _C.goldDim,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ), // Column
          ), // SizedBox
        ],
      ),
    );
  }
}

// ─── Login Card ───────────────────────────────────────────────────────────────
class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePass;
  final bool isLoading;
  final String? error;
  final Animation<double> shimmer;
  final VoidCallback onTogglePass;
  final VoidCallback? onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgot;

  const _LoginCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePass,
    required this.isLoading,
    required this.error,
    required this.shimmer,
    required this.onTogglePass,
    required this.onLogin,
    required this.onRegister,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top gold line accent
            Center(
              child: Container(
                width: 60,
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, _C.gold, Colors.transparent],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Email Field ──
            _GoldTextField(
              controller: emailCtrl,
              label: 'البريد الإلكتروني',
              hint: 'أدخل بريدك الإلكتروني',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'يرجى إدخال البريد الإلكتروني';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // ── Password Field ──
            _GoldTextField(
              controller: passwordCtrl,
              label: 'كلمة المرور',
              hint: 'أدخل كلمة المرور',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePass,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                // 👈 عند الضغط على Enter/Done بلوحة المفاتيح
                if (onLogin != null) onLogin!();
              },
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _C.goldDim,
                  size: 18,
                ),
                onPressed: onTogglePass,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                if (v.length < 6)
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                return null;
              },
            ),

            // ── Forgot password ──
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onForgot,
                style: TextButton.styleFrom(
                  foregroundColor: _C.gold,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Error message ──
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: _C.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: _C.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Login Button ──
            AnimatedBuilder(
              animation: shimmer,
              builder: (_, child) => Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFC4973A),
                      Color(0xFFA87A28),
                      Color(0xFF8A5D1E)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _C.gold.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      child!,
                      // shimmer sweep
                      if (!isLoading)
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(shimmer.value * 200, 0),
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: onLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFFF8E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Divider ──
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: _C.goldBorder.withOpacity(0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'أو',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: _C.goldDim.withOpacity(0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: _C.goldBorder.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Register link ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'طالب جديد في المركز؟ ',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Color(0x88F0E6C8),
                  ),
                ),
                GestureDetector(
                  onTap: onRegister,
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _C.gold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gold-styled text field ────────────────────────────────────────────────────
class _GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  // 👇 خصائص جديدة للوحة المفاتيح
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const _GoldTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction, // 👈
    this.onFieldSubmitted, // 👈
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: _C.goldDim,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction, // 👈 تمرير الإجراء
          onFieldSubmitted: onFieldSubmitted, // 👈 تمرير الحدث
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: _C.parchment,
          ),
          cursorColor: _C.gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Color(0x44F0E6C8),
            ),
            prefixIcon: Icon(icon, color: _C.goldDim, size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _C.inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.goldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.goldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.gold, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _C.error.withOpacity(0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.error),
            ),
            errorStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: _C.error,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom ornament ───────────────────────────────────────────────────────────
class _BottomOrnament extends StatelessWidget {
  const _BottomOrnament();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: CustomPaint(
        painter: _BottomArchPainter(),
        size: const Size(double.infinity, 40),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────
class _LoginBgPainter extends StatelessWidget {
  const _LoginBgPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BgPainter());
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0BC4973A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Bottom-left star
    _star(canvas, Offset(0, size.height * 0.88), 90, p);
    // Top-right star
    _star(canvas, Offset(size.width, size.height * 0.1), 100, p);
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final ox = c.dx + r * math.cos(a);
      final oy = c.dy + r * math.sin(a);
      final ir = r * 0.42;
      if (i == 0) path.moveTo(c.dx, c.dy);
      path
        ..lineTo(c.dx + ir * math.cos(a - 0.22), c.dy + ir * math.sin(a - 0.22))
        ..lineTo(ox, oy)
        ..lineTo(
            c.dx + ir * math.cos(a + 0.22), c.dy + ir * math.sin(a + 0.22));
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FaintStarPainter extends CustomPainter {
  final double radius;
  final double opacity;
  const _FaintStarPainter({required this.radius, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(196, 151, 58, opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final ox = cx + radius * math.cos(angle);
      final oy = cy + radius * math.sin(angle);
      final ir = radius * 0.42;
      if (i == 0) path.moveTo(cx, cy);
      path
        ..lineTo(
            cx + ir * math.cos(angle - 0.22), cy + ir * math.sin(angle - 0.22))
        ..lineTo(ox, oy)
        ..lineTo(
            cx + ir * math.cos(angle + 0.22), cy + ir * math.sin(angle + 0.22));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FiligreeCornerPainter extends CustomPainter {
  final bool flip;
  const _FiligreeCornerPainter({required this.flip});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33C4973A)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    if (flip) {
      canvas.drawLine(Offset(size.width, 0), Offset(0, 0), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    } else {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BottomArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x25C4973A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width * 0.85, size.height);
    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.25, size.height)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.3, size.width * 0.75, size.height);
    canvas.drawPath(path2, paint..color = const Color(0x15C4973A));

    // Center diamond dot
    final dotPaint = Paint()..color = const Color(0x55C4973A);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.1), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
