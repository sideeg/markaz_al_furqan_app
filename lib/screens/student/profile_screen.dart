// Path: lib/presentation/screens/student/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:markaz_al_furqan/constants/qiraat_types.dart';
import '../../services/auth_service.dart';
import '../../widgets/change_password_dialog.dart';

// ─── Adaptive Theme Colors (same palette class as register/login) ──────────────
class _TC {
  final bool isDark;
  const _TC(this.isDark);
  factory _TC.of(BuildContext ctx) =>
      _TC(Theme.of(ctx).brightness == Brightness.dark);

  Color get bg => isDark ? const Color(0xFF071A14) : const Color(0xFFF5F0E6);
  Color get card => isDark ? const Color(0xFF0C1E16) : Colors.white;
  Color get inputBg =>
      isDark ? const Color(0xFF0A1810) : const Color(0xFFFAF7F2);
  Color get headerG1 =>
      isDark ? const Color(0xFF0E5A38) : const Color(0xFF0E5A38);
  Color get headerG2 =>
      isDark ? const Color(0xFF071A14) : const Color(0xFF0A3D28);
  Color get gold => isDark ? const Color(0xFFC4973A) : const Color(0xFF9B7520);
  Color get goldDim =>
      isDark ? const Color(0x99C4973A) : const Color(0xCC9B7520);
  Color get goldFaint =>
      isDark ? const Color(0x18C4973A) : const Color(0x14A8782A);
  Color get goldBorder =>
      isDark ? const Color(0x33C4973A) : const Color(0x55A8782A);
  Color get primaryText =>
      isDark ? const Color(0xFFF0E6C8) : const Color(0xFF1C2B1F);
  Color get secondaryText =>
      isDark ? const Color(0x99F0E6C8) : const Color(0x99284030);
  Color get hintText =>
      isDark ? const Color(0x44F0E6C8) : const Color(0x66284030);
  Color get error => const Color(0xFFD05050);
  Color get sectionBadgeBg =>
      isDark ? const Color(0xFF122B1E) : const Color(0xFFEDF6EF);
  Color get sectionBadgeBorder =>
      isDark ? const Color(0x44C4973A) : const Color(0x66A8782A);
  Color get divider =>
      isDark ? const Color(0x22C4973A) : const Color(0x33A8782A);
  Color get optionBg => isDark ? const Color(0xFF0C1E16) : Colors.white;
  Color get optionBorder =>
      isDark ? const Color(0x22C4973A) : const Color(0x33A8782A);
}

// ─── Profile Screen ───────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  String? _selectedQiraat;
  bool _isEditing = false;
  bool _isLoading = false;

  late final List<String> _qiraatItems;

  // Animation for the edit-mode shimmer button
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _qiraatItems =
        QiraatTypes.values.map((e) => e.toString().split('.').last).toList();

    final user = ref.read(authServiceProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _selectedQiraat = user?.qiraat;

    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final user = ref.watch(authServiceProvider).user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: tc.bg,
        body: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator(color: tc.gold, strokeWidth: 2))
            : Stack(
                children: [
                  // Background subtle geometry
                  Positioned.fill(child: _ProfileBgPainter(tc: tc)),

                  // Full-width scrollable body
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Profile Hero Header ──────────────────────────
                          _ProfileHero(
                            tc: tc,
                            user: user,
                            isEditing: _isEditing,
                            shimmer: _shimmer,
                            onEditToggle: () {
                              if (_isEditing) {
                                _saveProfile();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                            onCancel: () => setState(() => _isEditing = false),
                          ),

                          // ── Form / Info Sections ─────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Personal info card
                                  _InfoCard(
                                    tc: tc,
                                    title: 'المعلومات الشخصية',
                                    icon: Icons.person_outline_rounded,
                                    child: Column(
                                      children: [
                                        _ProfileField(
                                          tc: tc,
                                          controller: _nameCtrl,
                                          label: 'الاسم الكامل',
                                          icon: Icons.person_outline_rounded,
                                          enabled: _isEditing,
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'يرجى إدخال الاسم';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _ProfileField(
                                          tc: tc,
                                          controller: _emailCtrl,
                                          label: 'البريد الإلكتروني',
                                          icon: Icons.alternate_email_rounded,
                                          enabled: false, // always locked
                                          trailingBadge: _LockedBadge(tc: tc),
                                        ),
                                        const SizedBox(height: 14),
                                        _ProfileField(
                                          tc: tc,
                                          controller: _phoneCtrl,
                                          label: 'رقم الجوال',
                                          icon: Icons.phone_outlined,
                                          enabled: _isEditing,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _QiraatField(
                                          tc: tc,
                                          isEditing: _isEditing,
                                          selectedValue: _selectedQiraat,
                                          items: _qiraatItems,
                                          onChanged: (v) => setState(
                                              () => _selectedQiraat = v),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Account actions card
                                  _InfoCard(
                                    tc: tc,
                                    title: 'إعدادات الحساب',
                                    icon: Icons.settings_outlined,
                                    child: Column(
                                      children: [
                                        _AccountOption(
                                          tc: tc,
                                          icon: Icons.lock_outlined,
                                          label: 'تغيير كلمة المرور',
                                          onTap: _showChangePasswordDialog,
                                        ),
                                        _GoldThinDivider(tc: tc),
                                        _AccountOption(
                                          tc: tc,
                                          icon: Icons.logout_rounded,
                                          label: 'تسجيل الخروج',
                                          isError: true,
                                          onTap: () => _confirmLogout(context),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),
                                ],
                              ),
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
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ok = await ref.read(authServiceProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          qiraat: _selectedQiraat,
        );

    setState(() {
      _isLoading = false;
      if (ok) {
        _isEditing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث الملف الشخصي بنجاح',
                style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: const Color(0xFF0E4D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _TC.of(context).goldBorder),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authServiceProvider).error ?? 'فشل في التحديث',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: const Color(0xFFD05050),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  void _confirmLogout(BuildContext context) {
    final tc = _TC.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        // استخدام اسم واضح للـ context الخاص بالـ Dialog
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: tc.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: tc.goldBorder),
          ),
          title: Text('تسجيل الخروج',
              style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tc.primaryText)),
          content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: tc.secondaryText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء',
                  style: TextStyle(fontFamily: 'Tajawal', color: tc.goldDim)),
            ),
            ElevatedButton(
              onPressed: () async {
                // 1. احفظ الـ Router قبل إغلاق الـ Dialog
                final router = GoRouter.of(context);
                // 2. أغلق الـ Dialog
                Navigator.pop(dialogContext);
                // 3. نفذ عملية تسجيل الخروج
                await ref.read(authServiceProvider.notifier).logout();
                // 4. انتقل بأمان لشاشة تسجيل الدخول
                router.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tc.error.withOpacity(0.9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('خروج',
                  style: TextStyle(
                      fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
  }
}

// ─── Profile Hero Header ──────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final _TC tc;
  final dynamic user;
  final bool isEditing;
  final Animation<double> shimmer;
  final VoidCallback onEditToggle;
  final VoidCallback onCancel;

  const _ProfileHero({
    required this.tc,
    required this.user,
    required this.isEditing,
    required this.shimmer,
    required this.onEditToggle,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tc.headerG1, tc.headerG2],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faint geometric background in the header
          Positioned(
            top: -40,
            right: -40,
            child: CustomPaint(
              painter:
                  _FaintStarPainter(color: tc.gold, radius: 110, opacity: 0.06),
              size: const Size(160, 160),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -20,
            child: CustomPaint(
              painter:
                  _FaintStarPainter(color: tc.gold, radius: 60, opacity: 0.04),
              size: const Size(100, 100),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Islamic geometric avatar ──
                _IslamicAvatar(tc: tc, user: user),

                const SizedBox(height: 16),

                Text(
                  user?.name ?? 'الطالب',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tc.isDark ? const Color(0xFFF0E6C8) : Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: tc.goldDim,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Edit / Save / Cancel buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isEditing) ...[
                        // Cancel
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: Icon(Icons.close_rounded,
                                size: 15, color: tc.goldDim),
                            label: Text('إلغاء',
                                style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13,
                                    color: tc.goldDim)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: tc.goldBorder),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Save button with shimmer
                        Expanded(
                          child: _SaveButton(
                              tc: tc,
                              shimmer: shimmer,
                              onPressed: onEditToggle),
                        ),
                      ] else
                        // Edit button
                        _EditButton(tc: tc, onPressed: onEditToggle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Islamic Avatar (8-point star orbit around circle) ────────────────────────
class _IslamicAvatar extends StatelessWidget {
  final _TC tc;
  final dynamic user;
  const _IslamicAvatar({required this.tc, required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user?.initials ?? 'م';
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating star ring
          CustomPaint(
            painter: _AvatarRingPainter(tc: tc),
            size: const Size(110, 110),
          ),
          // Avatar circle
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [tc.headerG1, tc.headerG2],
                center: const Alignment(-0.3, -0.3),
              ),
              border: Border.all(color: tc.gold.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: tc.gold.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: tc.isDark ? const Color(0xFFF0E6C8) : Colors.white,
                ),
              ),
            ),
          ),
          // Top gold dot accent
          Positioned(
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tc.gold,
                boxShadow: [
                  BoxShadow(color: tc.gold.withOpacity(0.4), blurRadius: 6)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRingPainter extends CustomPainter {
  final _TC tc;
  const _AvatarRingPainter({required this.tc});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 2;

    // Outer dashed ring
    final ringPaint = Paint()
      ..color = tc.gold.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // 8 diamond dots on ring
    final dotPaint = Paint()..color = tc.gold.withOpacity(0.6);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      final path = Path()
        ..moveTo(x, y - 3)
        ..lineTo(x + 2.5, y)
        ..lineTo(x, y + 3)
        ..lineTo(x - 2.5, y)
        ..close();
      canvas.drawPath(path, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Edit / Save Buttons ──────────────────────────────────────────────────────
class _EditButton extends StatelessWidget {
  final _TC tc;
  final VoidCallback onPressed;
  const _EditButton({required this.tc, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tc.isDark
              ? const [Color(0xFFC4973A), Color(0xFF8A5D1E)]
              : const [Color(0xFFA8782A), Color(0xFF704E18)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: tc.gold.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.white),
        label: const Text('تعديل الملف الشخصي',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final _TC tc;
  final Animation<double> shimmer;
  final VoidCallback onPressed;
  const _SaveButton(
      {required this.tc, required this.shimmer, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, child) => Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tc.isDark
                ? const [Color(0xFFC4973A), Color(0xFF8A5D1E)]
                : const [Color(0xFFA8782A), Color(0xFF704E18)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: tc.gold.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              child!,
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(shimmer.value * 150, 0),
                  child: Container(
                    width: 40,
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
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
        label: const Text('حفظ التعديلات',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final _TC tc;
  final String title;
  final IconData icon;
  final Widget child;
  const _InfoCard(
      {required this.tc,
      required this.title,
      required this.icon,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tc.isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: tc.goldFaint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tc.goldBorder),
                ),
                child: Icon(icon, color: tc.gold, size: 15),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tc.primaryText)),
              const Spacer(),
              // Decorative line
              Container(
                width: 40,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tc.gold.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tc.goldBorder, Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              )),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Profile Field ────────────────────────────────────────────────────────────
class _ProfileField extends StatelessWidget {
  final _TC tc;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? trailingBadge;

  const _ProfileField({
    required this.tc,
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = enabled ? tc.goldBorder : tc.divider;
    final fillColor = enabled ? tc.inputBg : tc.bg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: tc.goldDim,
                    letterSpacing: 0.5)),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              trailingBadge!,
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: enabled ? tc.primaryText : tc.secondaryText),
          cursorColor: tc.gold,
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: enabled ? tc.goldDim : tc.goldDim.withOpacity(0.4),
                size: 18),
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.divider.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.gold, width: 1.2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.error.withOpacity(0.6))),
            errorStyle:
                TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: tc.error),
          ),
        ),
      ],
    );
  }
}

// ─── Qiraat Read/Edit Field ───────────────────────────────────────────────────
class _QiraatField extends StatelessWidget {
  final _TC tc;
  final bool isEditing;
  final String? selectedValue;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _QiraatField(
      {required this.tc,
      required this.isEditing,
      required this.selectedValue,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نوع القراءة',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: tc.goldDim,
                  letterSpacing: 0.5)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: selectedValue,
            onChanged: onChanged,
            style: TextStyle(
                fontFamily: 'Tajawal', fontSize: 14, color: tc.primaryText),
            dropdownColor: tc.card,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: tc.goldDim, size: 20),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.record_voice_over_outlined,
                  color: tc.goldDim, size: 18),
              filled: true,
              fillColor: tc.inputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tc.goldBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tc.goldBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tc.gold, width: 1.2)),
            ),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: tc.primaryText)),
                    ))
                .toList(),
          ),
        ],
      );
    }

    // Read-only display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع القراءة',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: tc.goldDim,
                letterSpacing: 0.5)),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: tc.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tc.divider.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.record_voice_over_outlined,
                  color: tc.goldDim.withOpacity(0.4), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(selectedValue ?? 'غير محدد',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: tc.secondaryText)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Locked Badge ─────────────────────────────────────────────────────────────
class _LockedBadge extends StatelessWidget {
  final _TC tc;
  const _LockedBadge({required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tc.goldFaint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tc.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, color: tc.goldDim, size: 9),
          const SizedBox(width: 3),
          Text('محقق',
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 9,
                  color: tc.goldDim,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Account Option ───────────────────────────────────────────────────────────
class _AccountOption extends StatelessWidget {
  final _TC tc;
  final IconData icon;
  final String label;
  final bool isError;
  final VoidCallback onTap;

  const _AccountOption(
      {required this.tc,
      required this.icon,
      required this.label,
      required this.onTap,
      this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? tc.error : tc.primaryText;
    final iconColor = isError ? tc.error : tc.gold;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isError ? tc.error.withOpacity(0.08) : tc.goldFaint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isError ? tc.error.withOpacity(0.2) : tc.goldBorder,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ),
            Icon(Icons.arrow_back_ios_new_rounded,
                color: isError ? tc.error.withOpacity(0.5) : tc.goldDim,
                size: 13),
          ],
        ),
      ),
    );
  }
}

// ─── Thin Divider ─────────────────────────────────────────────────────────────
class _GoldThinDivider extends StatelessWidget {
  final _TC tc;
  const _GoldThinDivider({required this.tc});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: tc.divider.withOpacity(0.5));
}

// ─── Background Painter ───────────────────────────────────────────────────────
class _ProfileBgPainter extends StatelessWidget {
  final _TC tc;
  const _ProfileBgPainter({required this.tc});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BgPainter(tc: tc));
}

class _BgPainter extends CustomPainter {
  final _TC tc;
  const _BgPainter({required this.tc});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tc.gold.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    _drawStar(canvas, Offset(size.width + 15, size.height * 0.45), 80, paint);
    _drawStar(canvas, Offset(-15, size.height * 0.7), 60, paint);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final ir = r * 0.42;
      if (i == 0) path.moveTo(c.dx, c.dy);
      path
        ..lineTo(c.dx + ir * math.cos(a - 0.22), c.dy + ir * math.sin(a - 0.22))
        ..lineTo(c.dx + r * math.cos(a), c.dy + r * math.sin(a))
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
  final Color color;
  final double radius, opacity;
  const _FaintStarPainter(
      {required this.color, required this.radius, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final cx = size.width / 2, cy = size.height / 2;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final ir = radius * 0.42;
      if (i == 0) path.moveTo(cx, cy);
      path
        ..lineTo(cx + ir * math.cos(a - 0.22), cy + ir * math.sin(a - 0.22))
        ..lineTo(cx + radius * math.cos(a), cy + radius * math.sin(a))
        ..lineTo(cx + ir * math.cos(a + 0.22), cy + ir * math.sin(a + 0.22));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
