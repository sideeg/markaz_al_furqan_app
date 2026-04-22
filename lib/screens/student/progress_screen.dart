// Path: lib/presentation/screens/student/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

// إذا كنت تستخدم Syncfusion، يمكنك الإبقاء عليها، لكني سأستخدم رسومات مدمجة (CustomPainters)
// لتبدو أسرع وأكثر تناسقاً مع الثيم الإسلامي الخاص بنا.

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
  Color get mutedText =>
      isDark ? const Color(0x77F0E6C8) : const Color(0x88284030);
  Color get success => const Color(0xFF059669);
  Color get info => const Color(0xFF3B82F6);
  Color get error => const Color(0xFFDC2626);

  get secondaryText => const Color(0xFF059669);

  Color get warning => const Color.fromARGB(255, 153, 220, 38);
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(hifzStatisticsProvider);
    ref.invalidate(hifzProgressProvider);
    ref.invalidate(myCoursesProvider);
    _animCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final statsAsync = ref.watch(hifzStatisticsProvider);
    final progressAsync = ref.watch(hifzProgressProvider);
    final coursesAsync = ref.watch(myCoursesProvider);

    final completedCoursesCount =
        coursesAsync.valueOrNull?.where((c) => c.isCompleted).length ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: tc.bg,
        appBar: AppBar(
          backgroundColor: tc.bg,
          elevation: 0,
          title: Text(
            'إنجازي القرآني',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tc.primaryText,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: tc.gold),
              onPressed: _onRefresh,
            ),
          ],
        ),
        body: RefreshIndicator(
          color: tc.gold,
          backgroundColor: tc.card,
          onRefresh: _onRefresh,
          child: statsAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: tc.gold)),
            error: (e, _) => _buildErrorState(tc, e.toString()),
            data: (stats) {
              // بافتراض أن كلاس الإحصائيات يحمل البيانات الجديدة
              final totalAyahs = stats.totalAyahs ?? 0;
              final totalSessions = stats.totalSessions ?? 0;
              final avgEval = stats.averageEvaluation ?? 0.0;
              final quranPercent = stats.quranCompletionPercentage ?? 0.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── الدائرة الذهبية الكبرى (نسبة إنجاز القرآن) ────────
                    _buildMainProgressCircle(tc, quranPercent, totalAyahs),

                    const SizedBox(height: 24),

                    // ─── الكروت الإحصائية الصغيرة ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            tc: tc,
                            title: 'جلسات الحفظ',
                            value: '$totalSessions',
                            icon: Icons.access_time_filled_rounded,
                            color: tc.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            tc: tc,
                            title: 'دورات مكتملة',
                            value: '$completedCoursesCount',
                            icon: Icons.emoji_events_rounded,
                            color: tc.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            tc: tc,
                            title: 'متوسط التقييم',
                            value: avgEval.toStringAsFixed(1),
                            icon: Icons.star_rounded,
                            color: tc.gold,
                            isStar: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ─── عنوان قسم تقدم الدورات ─────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, color: tc.gold, size: 20),
                        const SizedBox(width: 8),
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

                    // ─── تقدم كل دورة على حدة ──────────────────────────────
                    progressAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (progressList) {
                        if (progressList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: tc.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tc.goldBorder),
                            ),
                            child: Center(
                              child: Text(
                                'لم تبدأ بتسجيل جلسات الحفظ بعد.\nابدأ رحلتك الآن!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: tc.mutedText,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: progressList.map<Widget>((prog) {
                            // تأكد أن الكلاس يحتوي على هذه البيانات حسب التحديث في Laravel
                            return _CourseProgressCard(
                              tc: tc,
                              courseName: prog.courseName ?? 'دورة',
                              ayahsCount: prog.totalAyahs ?? 0,
                              sessions: prog.sessionsCount ?? 0,
                              evaluationPercent: prog.evaluationPercent ?? 0.0,
                              animation: _progressAnim,
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainProgressCircle(_TC tc, double percent, int totalAyahs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tc.isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              final currentVal = percent * _progressAnim.value;
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: currentVal / 100,
                      strokeWidth: 12,
                      backgroundColor: tc.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(tc.gold),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${currentVal.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: tc.gold,
                            ),
                          ),
                          Text(
                            'من القرآن',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: tc.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tc.goldFaint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories_rounded, size: 16, color: tc.gold),
                const SizedBox(width: 8),
                Text(
                  'أتممت بفضل الله حفظ $totalAyahs آية',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tc.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(_TC tc, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: tc.error),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل إحصائياتك',
            style: TextStyle(
                fontFamily: 'Tajawal', fontSize: 16, color: tc.primaryText),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث الصفحة',
                style: TextStyle(fontFamily: 'Tajawal')),
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.gold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final _TC tc;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isStar;

  const _MiniStatCard({
    required this.tc,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tc.isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
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
              if (isStar) ...[
                const SizedBox(width: 2),
                Text(
                  '/5',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    color: tc.mutedText,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: tc.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final _TC tc;
  final String courseName;
  final int ayahsCount;
  final int sessions;
  final double evaluationPercent; // from 0 to 100
  final Animation<double> animation;

  const _CourseProgressCard({
    required this.tc,
    required this.courseName,
    required this.ayahsCount,
    required this.sessions,
    required this.evaluationPercent,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد لون التقييم حسب النسبة
    Color evalColor = tc.success;
    if (evaluationPercent < 60)
      evalColor = tc.error;
    else if (evaluationPercent < 80) evalColor = tc.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.goldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tc.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم الدورة
          Text(
            courseName,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: tc.primaryText,
            ),
          ),
          const SizedBox(height: 16),

          // شريط جودة الحفظ
          Row(
            children: [
              Text(
                'جودة ومستوى الحفظ:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: tc.mutedText,
                ),
              ),
              const Spacer(),
              Text(
                '${evaluationPercent.toInt()}%',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: evalColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (evaluationPercent / 100) * animation.value,
                  minHeight: 8,
                  backgroundColor: tc.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(evalColor),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: tc.goldBorder),
          const SizedBox(height: 12),

          // معلومات إضافية (آيات وجلسات)
          Row(
            children: [
              _buildSmallInfo(tc, Icons.menu_book_rounded, '$ayahsCount آية'),
              Container(
                  width: 1,
                  height: 20,
                  color: tc.goldBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildSmallInfo(
                  tc, Icons.history_rounded, '$sessions جلسة تسميع'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(_TC tc, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: tc.goldDim),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tc.secondaryText,
          ),
        ),
      ],
    );
  }
}
