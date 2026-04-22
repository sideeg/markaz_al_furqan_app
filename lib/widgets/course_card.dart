// Path: lib/widgets/course_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../models/course.dart';

// ─── Adaptive Theme Colors ────────────────────────────────────────────────────
class _TC {
  final bool isDark;
  const _TC(this.isDark);
  factory _TC.of(BuildContext ctx) =>
      _TC(Theme.of(ctx).brightness == Brightness.dark);

  Color get card => isDark ? const Color(0xFF0C1E16) : Colors.white;
  Color get gold => isDark ? const Color(0xFFC4973A) : const Color(0xFF9B7520);
  Color get goldDim =>
      isDark ? const Color(0x99C4973A) : const Color(0xCC9B7520);
  Color get goldBorder =>
      isDark ? const Color(0x33C4973A) : const Color(0x55A8782A);
  Color get goldFaint =>
      isDark ? const Color(0x18C4973A) : const Color(0x14A8782A);
  Color get primaryText =>
      isDark ? const Color(0xFFF0E6C8) : const Color(0xFF1C2B1F);
  Color get mutedText =>
      isDark ? const Color(0x77F0E6C8) : const Color(0x88284030);
  Color get surface =>
      isDark ? const Color(0xFF0A1810) : const Color(0xFFF5F0E6);
  Color get forestMid =>
      isDark ? const Color(0xFF0E4D32) : const Color(0xFF0E4D32);
  Color get success => const Color(0xFF059669);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFDC2626);
  Color get info => const Color(0xFF3B82F6);

  // Course type specific
  Color typeColor(String type) {
    switch (type) {
      case 'online':
        return info;
      case 'open':
        return success;
      case 'closed':
        return warning;
      default:
        return gold;
    }
  }
}

// ─── Animated Course Card ─────────────────────────────────────────────────────
// Wraps _CourseCardInner with a staggered entrance animation.
// index determines the delay so cards cascade into view.
class CourseCard extends StatefulWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool showEnrollmentStatus;
  final int animationIndex; // 0-based; controls entrance delay

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showEnrollmentStatus = true,
    this.animationIndex = 0,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        as Animation<double>;
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Staggered delay: max 480 ms so screen doesn't feel sluggish
    final delay =
        Duration(milliseconds: (widget.animationIndex * 70).clamp(0, 480));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _CourseCardInner(
          course: widget.course,
          onTap: widget.onTap,
          showEnrollmentStatus: widget.showEnrollmentStatus,
        ),
      ),
    );
  }
}

// ─── Inner Card Widget ────────────────────────────────────────────────────────
class _CourseCardInner extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool showEnrollmentStatus;

  const _CourseCardInner({
    required this.course,
    this.onTap,
    this.showEnrollmentStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tc.goldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(tc.isDark ? 0.25 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image / Placeholder ─────────────────────────────────────
              // إزالة الارتفاع الثابت (112) وجعل الصورة تأخذ Expanded لكي تتكيف مع الكارت
              Expanded(
                flex: 4, // تأخذ 4 أجزاء من المساحة
                child: _CardImage(course: course, tc: tc),
              ),

              // ── Info section ────────────────────────────────────────────
              Expanded(
                flex: 5, // تأخذ 5 أجزاء من المساحة لضمان عدم حدوث Overflow
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // يوزع العناصر
                    children: [
                      // Title
                      Text(
                        course.name,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tc.isDark
                              ? const Color(0xFFF0E6C8)
                              : const Color(0xFF1C2B1F),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Type badge
                      _TypeBadge(course: course, tc: tc),

                      // Bottom row: students + status
                      Row(
                        children: [
                          // Capacity mini-bar
                          Expanded(child: _CapacityRow(course: course, tc: tc)),
                          // Status icon
                          if (showEnrollmentStatus)
                            _StatusIcon(course: course, tc: tc),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card Image with Overlays ─────────────────────────────────────────────────
class _CardImage extends StatelessWidget {
  final Course course;
  final _TC tc;
  const _CardImage({required this.course, required this.tc});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image or placeholder
        Container(
          height: 112,
          width: double.infinity,
          child: course.imagePath != null
              ? CachedNetworkImage(
                  imageUrl: course.imagePath!,
                  fit: BoxFit.cover,
                  height: 112,
                  width: double.infinity,
                  placeholder: (_, __) => _PlaceholderImage(tc: tc),
                  errorWidget: (_, __, ___) => _PlaceholderImage(tc: tc),
                )
              : _PlaceholderImage(tc: tc),
        ),

        // ── COMPLETED overlay ────────────────────────────────────────────
        if (course.isCompleted)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.62),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tc.gold.withOpacity(0.15),
                      border: Border.all(
                          color: tc.gold.withOpacity(0.5), width: 1.5),
                    ),
                    child: Icon(Icons.emoji_events_rounded,
                        color: tc.gold, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text('انتهت الدورة',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tc.gold)),
                  if (course.completedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(course.completedAtFormatted,
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 9,
                            color: tc.gold.withOpacity(0.7))),
                  ],
                ],
              ),
            ),
          ),

        // ── REGISTRATION CLOSED ribbon ───────────────────────────────────
        if (!course.isCompleted && !course.isRegistrationOpen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDC2626).withOpacity(0.88),
                    const Color(0xFFB91C1C).withOpacity(0.88),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_outline_rounded,
                      color: Colors.white, size: 11),
                  SizedBox(width: 5),
                  Text('التسجيل مغلق',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),

        // ── FULL capacity banner ─────────────────────────────────────────
        if (!course.isCompleted && course.isRegistrationOpen && course.isFull)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.9),
                    const Color(0xFFD97706).withOpacity(0.9),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.group_off_rounded, color: Colors.white, size: 11),
                  SizedBox(width: 5),
                  Text('اكتملت الأماكن',
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),

        // ── Enrolled status badge (top-right corner) ─────────────────────
        if (course.isEnrolled && !course.isCompleted)
          Positioned(
            top: 8,
            left: 8,
            child: _EnrollmentBadge(course: course, tc: tc),
          ),
      ],
    );
  }
}

// ─── Placeholder Image ────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  final _TC tc;
  const _PlaceholderImage({required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tc.forestMid, const Color(0xFF071A14)],
        ),
      ),
      child: Stack(
        children: [
          // Faint Islamic star in background
          Center(
            child: CustomPaint(
              painter: _MiniStarPainter(color: tc.gold),
              size: const Size(70, 70),
            ),
          ),
          Center(
            child: Icon(Icons.menu_book_rounded,
                size: 32, color: tc.gold.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final Course course;
  final _TC tc;
  const _TypeBadge({required this.course, required this.tc});

  @override
  Widget build(BuildContext context) {
    final color = tc.typeColor(course.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        course.typeDisplayName,
        style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

// ─── Capacity Row ─────────────────────────────────────────────────────────────
class _CapacityRow extends StatelessWidget {
  final Course course;
  final _TC tc;
  const _CapacityRow({required this.course, required this.tc});

  @override
  Widget build(BuildContext context) {
    final pct = course.enrollmentPercentage;
    final barColor = pct >= 1.0
        ? tc.error
        : pct >= 0.8
            ? tc.warning
            : tc.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline_rounded, size: 11, color: tc.mutedText),
            const SizedBox(width: 3),
            Text(
              '${course.currentStudents}/${course.maxStudents}',
              style: TextStyle(
                  fontFamily: 'Tajawal', fontSize: 10, color: tc.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 3,
            backgroundColor: tc.surface,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ─── Enrollment Badge ─────────────────────────────────────────────────────────
class _EnrollmentBadge extends StatelessWidget {
  final Course course;
  final _TC tc;
  const _EnrollmentBadge({required this.course, required this.tc});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color border;
    late Color textColor;
    late IconData icon;
    late String label;

    switch (course.enrollmentStatus) {
      case 'approved':
        bg = tc.success.withOpacity(0.15);
        border = tc.success.withOpacity(0.5);
        textColor = tc.success;
        icon = Icons.check_circle_outline_rounded;
        label = 'مقبول';
        break;
      case 'pending':
        bg = tc.warning.withOpacity(0.15);
        border = tc.warning.withOpacity(0.5);
        textColor = tc.warning;
        icon = Icons.schedule_rounded;
        label = 'قيد المراجعة';
        break;
      case 'rejected':
        bg = tc.error.withOpacity(0.15);
        border = tc.error.withOpacity(0.5);
        textColor = tc.error;
        icon = Icons.cancel_outlined;
        label = 'مرفوض';
        break;
      case 'completed':
        bg = tc.gold.withOpacity(0.15);
        border = tc.goldBorder;
        textColor = tc.gold;
        icon = Icons.emoji_events_outlined;
        label = 'مكتمل';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
        ],
      ),
    );
  }
}

// ─── Status Icon (bottom row) ─────────────────────────────────────────────────
class _StatusIcon extends StatelessWidget {
  final Course course;
  final _TC tc;
  const _StatusIcon({required this.course, required this.tc});

  @override
  Widget build(BuildContext context) {
    if (course.isCompleted) {
      return Icon(Icons.emoji_events_rounded, size: 16, color: tc.gold);
    }
    if (!course.isRegistrationOpen) {
      return Icon(Icons.lock_outline_rounded, size: 16, color: tc.error);
    }
    if (course.isFull) {
      return Icon(Icons.group_rounded, size: 16, color: tc.warning);
    }
    if (course.isEnrolled) {
      switch (course.enrollmentStatus) {
        case 'approved':
          return Icon(Icons.check_circle_rounded, size: 16, color: tc.success);
        case 'pending':
          return Icon(Icons.schedule_rounded, size: 16, color: tc.warning);
        case 'rejected':
          return Icon(Icons.cancel_rounded, size: 16, color: tc.error);
      }
    }
    return const SizedBox.shrink();
  }
}

// ─── Mini star painter for placeholder background ────────────────────────────
class _MiniStarPainter extends CustomPainter {
  final Color color;
  const _MiniStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final ir = r * 0.42;
      if (i == 0) path.moveTo(cx, cy);
      path
        ..lineTo(cx + ir * math.cos(a - 0.22), cy + ir * math.sin(a - 0.22))
        ..lineTo(cx + r * math.cos(a), cy + r * math.sin(a))
        ..lineTo(cx + ir * math.cos(a + 0.22), cy + ir * math.sin(a + 0.22));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Compact Course Card (list view variant) ──────────────────────────────────
class CompactCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CompactCourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final typeColor = tc.typeColor(course.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.goldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(tc.isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Leading image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: course.imagePath != null
                    ? CachedNetworkImage(
                        imageUrl: course.imagePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _PlaceholderImage(tc: tc),
                        errorWidget: (_, __, ___) => _PlaceholderImage(tc: tc),
                      )
                    : _PlaceholderImage(tc: tc),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name,
                      style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tc.isDark
                              ? const Color(0xFFF0E6C8)
                              : const Color(0xFF1C2B1F)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(course.typeDisplayName,
                            style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: typeColor)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people_outline_rounded,
                          size: 11, color: tc.mutedText),
                      const SizedBox(width: 2),
                      Text('${course.currentStudents}/${course.maxStudents}',
                          style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 10,
                              color: tc.mutedText)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing status
            _StatusIcon(course: course, tc: tc),
          ],
        ),
      ),
    );
  }
}
