// Path: lib/presentation/screens/student/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../services/course_service.dart';
import '../../services/hifz_service.dart';

// ─── Adaptive Theme Colors ────────────────────────────────────────────────────
class _TC {
  final bool isDark;
  const _TC(this.isDark);
  factory _TC.of(BuildContext ctx) =>
      _TC(Theme.of(ctx).brightness == Brightness.dark);

  Color get bg => isDark ? const Color(0xFF071A14) : const Color(0xFFF5F0E6);
  Color get card => isDark ? const Color(0xFF0C1E16) : Colors.white;
  Color get surface =>
      isDark ? const Color(0xFF122B1E) : const Color(0xFFE8E3D5);
  Color get heroG1 => const Color(0xFF0E5A38);
  Color get heroG2 =>
      isDark ? const Color(0xFF030D09) : const Color(0xFF071A14);
  Color get gold => isDark ? const Color(0xFFC4973A) : const Color(0xFF9B7520);
  Color get goldLight =>
      isDark ? const Color(0xFFD4A84A) : const Color(0xFFB8882A);
  Color get goldDim =>
      isDark ? const Color(0x99C4973A) : const Color(0xCC9B7520);
  Color get goldFaint =>
      isDark ? const Color(0x1AC4973A) : const Color(0x15A8782A);
  Color get goldBorder =>
      isDark ? const Color(0x33C4973A) : const Color(0x44A8782A);
  Color get primaryText =>
      isDark ? const Color(0xFFF0E6C8) : const Color(0xFF1C2B1F);
  Color get mutedText =>
      isDark ? const Color(0x77F0E6C8) : const Color(0x88284030);
  Color get success => const Color(0xFF059669);
  Color get successFaint =>
      isDark ? const Color(0x1A059669) : const Color(0x12059669);
  Color get info => const Color(0xFF3B82F6);
  Color get infoFaint =>
      isDark ? const Color(0x1A3B82F6) : const Color(0x123B82F6);
  Color get error => const Color(0xFFDC2626);
  Color get errorFaint =>
      isDark ? const Color(0x1ADC2626) : const Color(0x12DC2626);
  Color get warning => const Color(0xFFF59E0B);
  Color get warningFaint =>
      isDark ? const Color(0x1AF59E0B) : const Color(0x12F59E0B);
  Color get purple => const Color(0xFF7C3AED);
}

// ─── Evaluation Helpers ───────────────────────────────────────────────────────
String _evalLabel(double pct) {
  if (pct >= 90) return 'ممتاز';
  if (pct >= 75) return 'جيد جداً';
  if (pct >= 60) return 'جيد';
  if (pct >= 40) return 'يحتاج تحسين';
  return 'ضعيف';
}

Color _evalColor(_TC tc, double pct) {
  if (pct >= 90) return tc.gold;
  if (pct >= 75) return tc.success;
  if (pct >= 60) return tc.info;
  if (pct >= 40) return tc.warning;
  return tc.error;
}

Color _evalFaint(_TC tc, double pct) {
  if (pct >= 90) return tc.goldFaint;
  if (pct >= 75) return tc.successFaint;
  if (pct >= 60) return tc.infoFaint;
  if (pct >= 40) return tc.warningFaint;
  return tc.errorFaint;
}

// ─── Custom Arc Painter ───────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color trackColor;
  final Color progressColor;
  final Color tickColor;

  const _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.tickColor,
  });

  // Arc spans 270° starting from bottom-left (225°) clockwise to bottom-right
  static const double _startAngle = -math.pi * 0.75; // –135° ≡ 225°
  static const double _totalSweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 20;

    // ── Decorative tick marks ──────────────────────────────────────────────
    const totalTicks = 72;
    for (int i = 0; i <= totalTicks; i++) {
      final angle = _startAngle + (_totalSweep * i / totalTicks);
      final isLong = i % 9 == 0;
      final isMid = i % 3 == 0;
      final innerR = radius +
          (isLong
              ? 4
              : isMid
                  ? 7
                  : 9);
      final outerR = radius + 12;
      final opacity = isLong
          ? 0.8
          : isMid
              ? 0.4
              : 0.2;

      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle),
            center.dy + innerR * math.sin(angle)),
        Offset(center.dx + outerR * math.cos(angle),
            center.dy + outerR * math.sin(angle)),
        Paint()
          ..color = tickColor.withOpacity(opacity)
          ..strokeWidth = isLong ? 2.0 : 1.0
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Track arc ─────────────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _totalSweep,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepProgress = _totalSweep * progress.clamp(0.0, 1.0);

    // ── Outer glow ────────────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      sweepProgress,
      false,
      Paint()
        ..color = progressColor.withOpacity(0.25)
        ..strokeWidth = 28
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Inner glow ────────────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      sweepProgress,
      false,
      Paint()
        ..color = progressColor.withOpacity(0.5)
        ..strokeWidth = 16
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Solid progress arc ────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      sweepProgress,
      false,
      Paint()
        ..color = progressColor
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Tip dot ───────────────────────────────────────────────────────────
    final tipAngle = _startAngle + sweepProgress;
    final tipCenter = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );

    // Halo
    canvas.drawCircle(
      tipCenter,
      12,
      Paint()
        ..color = progressColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // White fill
    canvas.drawCircle(
        tipCenter,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
    // Gold ring
    canvas.drawCircle(
      tipCenter,
      7,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─── Geometric Background Painter ─────────────────────────────────────────────
class _GeoPainter extends CustomPainter {
  final Color color;
  const _GeoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Eight-pointed star pattern (Islamic geometric motif)
    void drawStar(Offset center, double r) {
      const sides = 8;
      const angle = math.pi / sides;
      final path = Path();
      for (int i = 0; i < sides * 2; i++) {
        final a = i * angle - math.pi / 2;
        final rad = i.isEven ? r : r * 0.4;
        final x = center.dx + rad * math.cos(a);
        final y = center.dy + rad * math.sin(a);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw scattered stars
    drawStar(Offset(size.width * 0.08, size.height * 0.15), 18);
    drawStar(Offset(size.width * 0.92, size.height * 0.1), 14);
    drawStar(Offset(size.width * 0.05, size.height * 0.85), 12);
    drawStar(Offset(size.width * 0.95, size.height * 0.8), 16);
    drawStar(Offset(size.width * 0.5, size.height * 0.02), 10);
  }

  @override
  bool shouldRepaint(_GeoPainter old) => false;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Individual staggered animations
  late Animation<double> _arcAnim;
  late Animation<double> _statsSlide;
  late Animation<double> _statsOpacity;
  late Animation<double> _coursesSlide;
  late Animation<double> _coursesOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _arcAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );

    _statsSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _statsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.72, curve: Curves.easeOut),
      ),
    );

    _coursesSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _coursesOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(hifzStatisticsProvider);
    ref.invalidate(hifzProgressProvider);
    ref.invalidate(myCoursesProvider);
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final statsAsync = ref.watch(hifzStatisticsProvider);
    final progressAsync = ref.watch(hifzProgressProvider);
    final coursesAsync = ref.watch(myCoursesProvider);

    final completedCount =
        coursesAsync.valueOrNull?.where((c) => c.isCompleted).length ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: tc.bg,
        // ── App Bar ────────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: tc.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_rounded, color: tc.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'إنجازي القرآني',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: tc.primaryText,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: tc.gold),
              onPressed: _onRefresh,
              tooltip: 'تحديث',
            ),
          ],
        ),

        body: RefreshIndicator(
          color: tc.gold,
          backgroundColor: tc.card,
          onRefresh: _onRefresh,
          child: statsAsync.when(
            loading: () => _buildSkeleton(tc),
            error: (e, _) => _buildError(tc, e.toString()),
            data: (stats) =>
                _buildBody(tc, stats, progressAsync, completedCount),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(
    _TC tc,
    dynamic stats,
    AsyncValue<List<CourseProgress>> progressAsync,
    int completedCount,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero card (gradient + arc) ──────────────────────────────────
          _QuranHeroCard(
            tc: tc,
            percent: stats.quranCompletionPercentage,
            totalAyahs: stats.totalAyahs,
            animation: _arcAnim,
          ),

          const SizedBox(height: 20),

          // ── Stats row ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => Opacity(
              opacity: _statsOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _statsSlide.value),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      tc: tc,
                      label: 'جلسات التسميع',
                      value: '${stats.totalSessions ?? 0}',
                      icon: Icons.history_edu_rounded,
                      color: tc.info,
                      faint: tc.infoFaint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      tc: tc,
                      label: 'دورات مكتملة',
                      value: '$completedCount',
                      icon: Icons.emoji_events_rounded,
                      color: tc.success,
                      faint: tc.successFaint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      tc: tc,
                      label: 'التقييم',
                      value:
                          (stats.averageEvaluation ?? 0.0).toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: tc.gold,
                      faint: tc.goldFaint,
                      suffix: '/5',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Courses section ────────────────────────────────────────────
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) => Opacity(
              opacity: _coursesOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _coursesSlide.value),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: tc.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'تفاصيل الإنجاز في الدورات',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: tc.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Course list
                  progressAsync.when(
                    loading: () => _buildCoursesSkeleton(tc),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (list) {
                      if (list.isEmpty) {
                        return _buildEmptyState(tc);
                      }
                      return Column(
                        children: list.asMap().entries.map((entry) {
                          return _CourseCard(
                            tc: tc,
                            prog: entry.value,
                            animation: _arcAnim,
                            index: entry.key,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton loader ───────────────────────────────────────────────────────
  Widget _buildSkeleton(_TC tc) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _shimmer(tc, height: 300, margin: EdgeInsets.zero, radius: 0),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _shimmer(tc, height: 100),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _shimmer(tc, height: 140),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(_TC tc,
      {double height = 80, EdgeInsets? margin, double radius = 16}) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildCoursesSkeleton(_TC tc) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _shimmer(tc, height: 140),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(_TC tc) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.goldBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 52, color: tc.goldDim),
          const SizedBox(height: 16),
          Text(
            'لم تبدأ بتسجيل جلسات الحفظ بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: tc.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ رحلتك مع القرآن الكريم الآن\nوسجّل أول جلسة حفظ!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: tc.mutedText,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildError(_TC tc, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tc.errorFaint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: tc.error),
            ),
            const SizedBox(height: 20),
            Text(
              'تعذّر تحميل إحصائياتك',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tc.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحقق من اتصالك بالإنترنت وحاول مجدداً',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: tc.mutedText,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Tajawal')),
              style: FilledButton.styleFrom(
                backgroundColor: tc.gold,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quran Hero Card ──────────────────────────────────────────────────────────
class _QuranHeroCard extends StatelessWidget {
  final _TC tc;
  final double percent;
  final int totalAyahs;
  final Animation<double> animation;

  const _QuranHeroCard({
    required this.tc,
    required this.percent,
    required this.totalAyahs,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tc.heroG1, tc.heroG2],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Islamic geometric background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _GeoPainter(tc.gold.withOpacity(0.12)),
            ),
          ),

          // Radial glow behind arc
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tc.gold.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                // Top label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: tc.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: tc.gold.withOpacity(0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mosque_rounded,
                          color: tc.gold.withOpacity(0.9), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'نسبة إتمام القرآن الكريم',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tc.gold.withOpacity(0.9),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Arc widget
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final animPercent = percent * animation.value;
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(200, 200),
                            painter: _ArcPainter(
                              progress: (animPercent / 100).clamp(0.0, 1.0),
                              trackColor: Colors.white.withOpacity(0.08),
                              progressColor: tc.gold,
                              tickColor: Colors.white,
                            ),
                          ),
                          // Center text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${animPercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: tc.goldLight,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 50,
                                height: 1,
                                color: tc.gold.withOpacity(0.3),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'من القرآن',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Ayah chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_added_rounded,
                          size: 16, color: tc.gold),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: 'أتممتَ بفضل الله مع دورات الفرقان حفظ ',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            children: [
                              TextSpan(
                                text: '$totalAyahs',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: tc.gold,
                                ),
                              ),
                              const TextSpan(text: ' آية'),
                            ],
                          ),
                        ),
                      ),
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

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _TC tc;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color faint;
  final String? suffix;

  const _StatCard({
    required this.tc,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.faint,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tc.isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: faint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),

          // Value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: tc.primaryText,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    color: tc.mutedText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: tc.mutedText,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Course Progress Card ─────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final _TC tc;
  final CourseProgress prog;
  final Animation<double> animation;
  final int index;

  const _CourseCard({
    required this.tc,
    required this.prog,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final evalPct = prog.evaluationPercent ?? 0.0;
    final evalColor = _evalColor(tc, evalPct);
    final evalFaint = _evalFaint(tc, evalPct);
    final evalLabel = _evalLabel(evalPct);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tc.isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card header (colored stripe + name + badge) ──────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: evalFaint,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: tc.goldBorder)),
            ),
            child: Row(
              children: [
                // Course name
                Expanded(
                  child: Text(
                    prog.courseName ?? 'دورة',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tc.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),

                // Evaluation badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: evalColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: evalColor.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        evalPct >= 75
                            ? Icons.verified_rounded
                            : evalPct >= 50
                                ? Icons.trending_up_rounded
                                : Icons.trending_flat_rounded,
                        size: 12,
                        color: evalColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        evalLabel,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: evalColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar section ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'جودة الحفظ',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: tc.mutedText,
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) => Text(
                        '${(evalPct * animation.value).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: evalColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Segmented-style progress bar
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          // Track
                          Container(
                            height: 10,
                            color: tc.surface,
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor:
                                ((evalPct / 100) * animation.value).clamp(0, 1),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    evalColor.withOpacity(0.7),
                                    evalColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Footer stats ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                _InfoPill(
                  tc: tc,
                  icon: Icons.menu_book_rounded,
                  label: '${prog.totalAyahs ?? 0} آية',
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: tc.goldBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                _InfoPill(
                  tc: tc,
                  icon: Icons.record_voice_over_rounded,
                  label: '${prog.sessionsCount ?? 0} جلسة تسميع',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Pill ────────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final _TC tc;
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.tc,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tc.goldDim),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tc.mutedText,
          ),
        ),
      ],
    );
  }
}
