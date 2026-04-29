// Path: lib/presentation/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../constants/qiraat_types.dart';
import '../../services/auth_service.dart';

// ─── Constants List ───────────────────────────────────────────────────────────
// قائمة الجنسيات بناءً على التحديث السابق
const List<String> nationalitiesList = [
  'سعودي',
  'مصري',
  'أردني',
  'إماراتي',
  'بحريني',
  'كويتي',
  'عماني',
  'قطري',
  'فلسطيني',
  'سوري',
  'لبناني',
  'عراقي',
  'يمني',
  'سوداني',
  'ليبي',
  'تونسي',
  'جزائري',
  'مغربي',
  'موريتاني',
  'صومالي',
  'جيبوتي',
  'تركي',
  'باكستاني',
  'هندي',
  'بنغلاديشي',
  'أفغاني',
  'إندونيسي',
  'ماليزي',
  'أمريكي',
  'بريطاني',
  'كندي',
  'أسترالي',
  'أوروبي',
  'أخرى'
];

// ─── Adaptive Theme Colors ────────────────────────────────────────────────────
// All color decisions live here. Toggle isDark to flip the entire palette.
class _TC {
  final bool isDark;
  const _TC(this.isDark);

  factory _TC.of(BuildContext ctx) =>
      _TC(Theme.of(ctx).brightness == Brightness.dark);

  // Backgrounds
  Color get bg => isDark ? const Color(0xFF071A14) : const Color(0xFFF5F0E6);
  Color get card => isDark ? const Color(0xFF0C1E16) : Colors.white;
  Color get inputBg =>
      isDark ? const Color(0xFF0A1810) : const Color(0xFFFAF7F2);
  Color get headerG1 =>
      isDark ? const Color(0xFF0E5A38) : const Color(0xFF0E5A38);
  Color get headerG2 =>
      isDark ? const Color(0xFF071A14) : const Color(0xFF0A3D28);

  // Gold — slightly deeper on light to maintain contrast
  Color get gold => isDark ? const Color(0xFFC4973A) : const Color(0xFF9B7520);
  Color get goldDim =>
      isDark ? const Color(0x99C4973A) : const Color(0xCC9B7520);
  Color get goldFaint =>
      isDark ? const Color(0x18C4973A) : const Color(0x14A8782A);
  Color get goldBorder =>
      isDark ? const Color(0x33C4973A) : const Color(0x55A8782A);

  // Text
  Color get primaryText =>
      isDark ? const Color(0xFFF0E6C8) : const Color(0xFF1C2B1F);
  Color get secondaryText =>
      isDark ? const Color(0x99F0E6C8) : const Color(0x99284030);
  Color get hintText =>
      isDark ? const Color(0x44F0E6C8) : const Color(0x66284030);

  // Semantic
  Color get error => const Color(0xFFD05050);

  // Section header badge
  Color get sectionBadgeBg =>
      isDark ? const Color(0xFF122B1E) : const Color(0xFFEDF6EF);
  Color get sectionBadgeBorder =>
      isDark ? const Color(0x44C4973A) : const Color(0x66A8782A);

  // Divider
  Color get divider =>
      isDark ? const Color(0x22C4973A) : const Color(0x33A8782A);

  // Chip / tag
  Color get chipBg =>
      isDark ? const Color(0xFF0F2A1E) : const Color(0xFFF0EBE0);
}

// ─── Register Screen ──────────────────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _nationalIdFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  String? _selectedQiraat;
  String? _selectedNationality; // 👈 المتغير الجديد للجنسية
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
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
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalIdCtrl.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _nationalIdFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      passwordConfirmation: _confirmPasswordCtrl.text,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      nationalId: _nationalIdCtrl.text.trim().isNotEmpty
          ? _nationalIdCtrl.text.trim()
          : null,
      qiraat: _selectedQiraat,
      nationality: _selectedNationality, // 👈 إرسال الجنسية للخادم
      gender: _selectedGender,
    );
    if (success && mounted) context.go('/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final authState = ref.watch(authServiceProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: tc.bg,
        body: Stack(
          children: [
            // ── Background geometric layer ──
            Positioned.fill(child: _RegisterBgPainter(tc: tc)),

            // ── Scrollable body ──
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──
                    _RegisterHeader(tc: tc, onBack: () => context.go('/login')),

                    // ── Form card (overlaps header) ──
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _FormCard(
                          nameFocus: _nameFocus, // ← ADD
                          emailFocus: _emailFocus, // ← ADD
                          phoneFocus: _phoneFocus, // ← ADD
                          nationalIdFocus: _nationalIdFocus, // ← ADD
                          passwordFocus: _passwordFocus, // ← ADD
                          confirmPasswordFocus: _confirmPasswordFocus,
                          tc: tc,
                          formKey: _formKey,
                          nameCtrl: _nameCtrl,
                          emailCtrl: _emailCtrl,
                          phoneCtrl: _phoneCtrl,
                          nationalIdCtrl: _nationalIdCtrl,
                          passwordCtrl: _passwordCtrl,
                          confirmPasswordCtrl: _confirmPasswordCtrl,
                          selectedGender: _selectedGender,
                          selectedQiraat: _selectedQiraat,
                          selectedNationality:
                              _selectedNationality, // 👈 تمرير المتغير الجديد
                          obscurePassword: _obscurePassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          isLoading: authState.isLoading,
                          error: authState.error,
                          shimmer: _shimmer,
                          onGenderChanged: (v) =>
                              setState(() => _selectedGender = v),
                          onQiraatChanged: (v) =>
                              setState(() => _selectedQiraat = v),
                          onNationalityChanged: (v) => // 👈 تحديث قيمة الجنسية
                              setState(() => _selectedNationality = v),
                          onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onToggleConfirm: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          onRegister: authState.isLoading ? null : _register,
                          onLogin: () => context.go('/login'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _RegisterHeader extends StatelessWidget {
  final _TC tc;
  final VoidCallback onBack;
  const _RegisterHeader({required this.tc, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 42),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tc.headerG1, tc.headerG2],
          stops: const [0.0, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(44),
          bottomRight: Radius.circular(44),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background faint star (تم تحديث withOpacity لـ withValues)
          Positioned(
            top: -30,
            left: -20,
            child: CustomPaint(
              painter:
                  _FaintStarPainter(color: tc.gold, radius: 100, opacity: 0.07),
              size: const Size(140, 140),
            ),
          ),
          Positioned(
            bottom: 0,
            right: -30,
            child: CustomPaint(
              painter:
                  _FaintStarPainter(color: tc.gold, radius: 70, opacity: 0.05),
              size: const Size(100, 100),
            ),
          ),

          // Back button
          Positioned(
            top: 0,
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_forward_ios_rounded,
                    color: tc.gold.withValues(alpha: 0.7), size: 18),
              ),
            ),
          ),

          // Center content
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ornament icon in a gold ring
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [tc.headerG1, tc.headerG2],
                    ),
                    border: Border.all(color: tc.goldBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: tc.gold.withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      color: tc.gold, size: 30),
                ),

                const SizedBox(height: 16),

                Text(
                  'انضم إلى مركز الفرقان',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tc.isDark ? const Color(0xFFF0E6C8) : Colors.white,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'أنشئ حسابك وابدأ رحلة حفظ القرآن الكريم',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: tc.goldDim,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form Card ────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final FocusNode nameFocus,
      emailFocus,
      phoneFocus,
      nationalIdFocus,
      passwordFocus,
      confirmPasswordFocus;
  final _TC tc;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl,
      emailCtrl,
      phoneCtrl,
      nationalIdCtrl,
      passwordCtrl,
      confirmPasswordCtrl;
  final String? selectedGender, selectedQiraat, selectedNationality;
  final bool obscurePassword, obscureConfirmPassword, isLoading;
  final String? error;
  final Animation<double> shimmer;
  final ValueChanged<String?> onGenderChanged,
      onQiraatChanged,
      onNationalityChanged;
  final VoidCallback onTogglePassword, onToggleConfirm;
  final VoidCallback? onRegister;
  final VoidCallback onLogin;

  const _FormCard({
    required this.nameFocus, // ← ADD
    required this.emailFocus, // ← ADD
    required this.phoneFocus, // ← ADD
    required this.nationalIdFocus, // ← ADD
    required this.passwordFocus, // ← ADD
    required this.confirmPasswordFocus,
    required this.tc,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.nationalIdCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.selectedGender,
    required this.selectedQiraat,
    required this.selectedNationality, // 👈
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.error,
    required this.shimmer,
    required this.onGenderChanged,
    required this.onQiraatChanged,
    required this.onNationalityChanged, // 👈
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tc.isDark ? 0.35 : 0.08),
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
            // Top gold accent line
            Center(
              child: Container(
                width: 60,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, tc.gold, Colors.transparent],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 1: المعلومات الأساسية ──────────────────────────────
            _SectionHeader(
                tc: tc,
                icon: Icons.person_outline_rounded,
                label: 'المعلومات الأساسية'),
            const SizedBox(height: 16),

            _GoldTextField(
              tc: tc,
              controller: nameCtrl,
              focusNode: nameFocus, // ← ADD
              textInputAction: TextInputAction.next, // ← ADD
              onFieldSubmitted: (_) => emailFocus.requestFocus(),
              label: 'الاسم الكامل *',
              hint: 'أدخل اسمك الكامل',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال الاسم الكامل';
                if (v.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                return null;
              },
            ),

            const SizedBox(height: 14),

            _GoldTextField(
              tc: tc,
              controller: emailCtrl,
              focusNode: emailFocus, // ← ADD
              textInputAction: TextInputAction.next, // ← ADD
              onFieldSubmitted: (_) => phoneFocus.requestFocus(),
              label: 'البريد الإلكتروني *',
              hint: 'أدخل بريدك الإلكتروني',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'يرجى إدخال البريد الإلكتروني';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'يرجى إدخال بريد إلكتروني صحيح';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Phone + National ID in a 2-column row
            Row(
              children: [
                Expanded(
                  child: _GoldTextField(
                    tc: tc,
                    controller: phoneCtrl,
                    focusNode: phoneFocus, // ← ADD
                    textInputAction: TextInputAction.next, // ← ADD
                    onFieldSubmitted: (_) => nationalIdFocus.requestFocus(),
                    label: 'رقم الهاتف',
                    hint: '05xxxxxxxx',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null) {
                        return 'رقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GoldTextField(
                    tc: tc,
                    controller: nationalIdCtrl,
                    focusNode: nationalIdFocus, // ← ADD
                    textInputAction: TextInputAction.next, // ← ADD
                    onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                    label: 'رقم الهوية',
                    hint: '1xxxxxxxxx',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 8) {
                        return '8 أرقام على الأقل';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            _GoldDivider(tc: tc),
            const SizedBox(height: 22),

            // ── Section 2: التفضيلات ───────────────────────────────────────
            _SectionHeader(
                tc: tc, icon: Icons.tune_rounded, label: 'التفضيلات'),
            const SizedBox(height: 16),

            // Gender as segmented chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الجنس *',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: tc.goldDim,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _GenderChip(
                      tc: tc,
                      label: 'ذكر',
                      icon: Icons.male_rounded,
                      selected: selectedGender == 'ذكر',
                      onTap: () => onGenderChanged('ذكر'),
                    ),
                    const SizedBox(width: 10),
                    _GenderChip(
                      tc: tc,
                      label: 'أنثى',
                      icon: Icons.female_rounded,
                      selected: selectedGender == 'أنثي',
                      onTap: () => onGenderChanged('أنثي'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Nationality Dropdown Field
            _GoldDropdownField(
              tc: tc,
              label: 'الجنسية *',
              hint: 'اختر الجنسية',
              icon: Icons.flag_outlined,
              value: selectedNationality,
              items: nationalitiesList,
              onChanged: onNationalityChanged,
              validator: (v) => v == null ? 'يرجى اختيار الجنسية' : null,
            ),

            const SizedBox(height: 14),

            _GoldDropdownField(
              tc: tc,
              label: 'القراءة المفضلة *',
              hint: 'اختر القراءة',
              icon: Icons.record_voice_over_outlined,
              value: selectedQiraat,
              items: QiraatTypes.values
                  .map((e) => e.toString().split('.').last)
                  .toList(),
              onChanged: onQiraatChanged,
              validator: (v) => v == null ? 'يرجى اختيار القراءة' : null,
            ),

            const SizedBox(height: 22),
            _GoldDivider(tc: tc),
            const SizedBox(height: 22),

            // ── Section 3: الأمان ──────────────────────────────────────────
            _SectionHeader(
                tc: tc, icon: Icons.shield_outlined, label: 'الأمان'),
            const SizedBox(height: 16),

            _GoldTextField(
              tc: tc,
              controller: passwordCtrl,
              focusNode: passwordFocus, // ← ADD
              textInputAction: TextInputAction.next, // ← ADD
              onFieldSubmitted: (_) => confirmPasswordFocus.requestFocus(),
              label: 'كلمة المرور *',
              hint: '8 أحرف على الأقل',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: tc.goldDim,
                  size: 18,
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                if (v.length < 8)
                  return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                return null;
              },
            ),

            const SizedBox(height: 14),

            _GoldTextField(
              tc: tc,
              controller: confirmPasswordCtrl,
              focusNode: confirmPasswordFocus, // ← ADD
              textInputAction: TextInputAction.done, // ← ADD (last field)
              onFieldSubmitted: (_) => onRegister?.call(),
              label: 'تأكيد كلمة المرور *',
              hint: 'أعد إدخال كلمة المرور',
              icon: Icons.lock_outline_rounded,
              obscureText: obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: tc.goldDim,
                  size: 18,
                ),
                onPressed: onToggleConfirm,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                if (v != passwordCtrl.text) return 'كلمة المرور غير متطابقة';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Error message ──
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tc.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tc.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: tc.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: tc.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Register button ──
            _GoldButton(
                tc: tc,
                shimmer: shimmer,
                isLoading: isLoading,
                label: 'إنشاء الحساب',
                onPressed: onRegister),

            const SizedBox(height: 20),

            // ── Divider ──
            Row(
              children: [
                Expanded(child: Container(height: 1, color: tc.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('أو',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: tc.goldDim.withValues(alpha: 0.6))),
                ),
                Expanded(child: Container(height: 1, color: tc.divider)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Login link ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('لديك حساب بالفعل؟ ',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: tc.secondaryText)),
                GestureDetector(
                  onTap: onLogin,
                  child: Text('تسجيل الدخول',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tc.gold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final _TC tc;
  final IconData icon;
  final String label;
  const _SectionHeader(
      {required this.tc, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tc.sectionBadgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tc.sectionBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tc.gold, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tc.gold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gold Divider ─────────────────────────────────────────────────────────────
class _GoldDivider extends StatelessWidget {
  final _TC tc;
  const _GoldDivider({required this.tc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: tc.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tc.goldBorder,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: tc.divider)),
      ],
    );
  }
}

// ─── Gender Chip ──────────────────────────────────────────────────────────────
class _GenderChip extends StatelessWidget {
  final _TC tc;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GenderChip(
      {required this.tc,
      required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? tc.goldFaint : tc.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? tc.gold : tc.goldBorder,
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? tc.gold : tc.goldDim.withValues(alpha: 0.5),
                  size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? tc.gold : tc.secondaryText,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gold Text Field ──────────────────────────────────────────────────────────
class _GoldTextField extends StatelessWidget {
  final _TC tc;
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final FocusNode? focusNode; // ← ADD
  final TextInputAction? textInputAction; // ← ADD
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _GoldTextField({
    required this.tc,
    required this.controller,
    this.focusNode, // ← ADD
    this.textInputAction, // ← ADD
    this.onFieldSubmitted,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: tc.goldDim,
                letterSpacing: 0.5)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode, // ← ADD
          textInputAction: textInputAction, // ← ADD
          onFieldSubmitted: onFieldSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(
              fontFamily: 'Tajawal', fontSize: 14, color: tc.primaryText),
          cursorColor: tc.gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontFamily: 'Tajawal', fontSize: 12, color: tc.hintText),
            prefixIcon: Icon(icon, color: tc.goldDim, size: 18),
            suffixIcon: suffixIcon,
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
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.error.withValues(alpha: 0.6))),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.error)),
            errorStyle:
                TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: tc.error),
          ),
        ),
      ],
    );
  }
}

// ─── Gold Dropdown Field ──────────────────────────────────────────────────────
class _GoldDropdownField extends StatelessWidget {
  final _TC tc;
  final String label, hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _GoldDropdownField({
    required this.tc,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: tc.goldDim,
                letterSpacing: 0.5)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
              fontFamily: 'Tajawal', fontSize: 14, color: tc.primaryText),
          dropdownColor: tc.card,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: tc.goldDim, size: 20),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontFamily: 'Tajawal', fontSize: 12, color: tc.hintText),
            prefixIcon: Icon(icon, color: tc.goldDim, size: 18),
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
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tc.error.withValues(alpha: 0.6))),
            errorStyle:
                TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: tc.error),
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
}

// ─── Gold Button ──────────────────────────────────────────────────────────────
class _GoldButton extends StatelessWidget {
  final _TC tc;
  final Animation<double> shimmer;
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  const _GoldButton(
      {required this.tc,
      required this.shimmer,
      required this.isLoading,
      required this.label,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedBuilder(
        animation: shimmer,
        builder: (_, child) => Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: tc.isDark
                  ? const [
                      Color(0xFFC4973A),
                      Color(0xFFA87A28),
                      Color(0xFF8A5D1E)
                    ]
                  : const [
                      Color(0xFFA8782A),
                      Color(0xFF8A6020),
                      Color(0xFF704E18)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: tc.gold.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.center, // 👈 التوسيط السحري هنا
              children: [
                if (!isLoading)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(shimmer.value * 200, 0),
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // النص أوالدائرة المتحركة في المنتصف
                isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        label,
                        style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFF8E8),
                            letterSpacing: 0.5),
                        textAlign: TextAlign.center,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────
class _RegisterBgPainter extends StatelessWidget {
  final _TC tc;
  const _RegisterBgPainter({required this.tc});

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
      ..color = tc.gold.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    _drawStar(canvas, Offset(size.width + 20, size.height * 0.55), 90, paint);
    _drawStar(canvas, Offset(-20, size.height * 0.75), 70, paint);
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
      ..color = color.withValues(alpha: opacity)
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
