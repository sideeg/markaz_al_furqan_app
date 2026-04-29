import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../../../widgets/course_card.dart';

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
  Color get mutedText =>
      isDark ? const Color(0x77F0E6C8) : const Color(0x88284030);
  Color get divider =>
      isDark ? const Color(0x22C4973A) : const Color(0x33A8782A);
  Color get success => const Color(0xFF059669);
  Color get warning => const Color(0xFFF59E0B);
  Color get error => const Color(0xFFDC2626);
}

// ─── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  DateTime? _lastRefreshTime;
  double _headerCollapse = 0.0;
  bool _coursesHaveAnimated = false;

  late AnimationController _headerGlowCtrl;
  late Animation<double> _headerGlow;

  static const double _kHeaderMax = 200.0;
  static const double _kHeaderMin = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headerGlowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
    _headerGlow = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _headerGlowCtrl, curve: Curves.easeInOut));
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollCtrl.offset.clamp(0.0, _kHeaderMax - _kHeaderMin);
    final progress = offset / (_kHeaderMax - _kHeaderMin);
    if ((progress - _headerCollapse).abs() > 0.01) {
      setState(() => _headerCollapse = progress);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _headerGlowCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!) >
            const Duration(minutes: 5)) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final user = ref.watch(authServiceProvider).user;
    final coursesAsync = ref.watch(coursesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: tc.bg,
          body: Stack(
            children: [
              Positioned.fill(child: _HomeBgPainter(tc: tc)),
              RefreshIndicator(
                onRefresh: _refreshData,
                color: tc.gold,
                backgroundColor: tc.card,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ─────────────────────────────────────────────
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HomeHeaderDelegate(
                        tc: tc,
                        user: user,
                        glow: _headerGlow,
                        collapseAmt: _headerCollapse,
                        onProfile: () => context.go('/student/profile'),
                        onRefresh: coursesAsync.isLoading ? null : _refreshData,
                        onNotify: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('الإشعارات قريباً',
                                style: TextStyle(fontFamily: 'Tajawal')),
                            backgroundColor: tc.card,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: tc.goldBorder),
                            ),
                          ),
                        ),
                        isLoading: coursesAsync.isLoading,
                        minHeight: _kHeaderMin,
                        maxHeight: _kHeaderMax,
                      ),
                    ),

                    // ── Stats ──────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: coursesAsync.maybeWhen(
                        data: (courses) => _StatsRow(tc: tc, courses: courses),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),

                    // ── Search ─────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        child: _GoldSearchBar(
                          tc: tc,
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                    ),

                    // ── Filters ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _GoldFilterRow(
                        tc: tc,
                        selectedFilter: _selectedFilter,
                        onChanged: (f) => setState(() {
                          _selectedFilter = f;
                          _coursesHaveAnimated = false;
                        }),
                      ),
                    ),

                    // ── Last refreshed ─────────────────────────────────────
                    if (_lastRefreshTime != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          child: Text(
                            'آخر تحديث: ${_formatTime(_lastRefreshTime!)}',
                            style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10,
                                color: tc.mutedText),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // ── Course grid ────────────────────────────────────────
                    coursesAsync.when(
                      data: (courses) {
                        final filtered = _filterCourses(courses);
                        if (filtered.isEmpty) {
                          return SliverFillRemaining(
                            child: _EmptyState(tc: tc, query: _searchQuery),
                          );
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_coursesHaveAnimated && mounted) {
                            setState(() => _coursesHaveAnimated = true);
                          }
                        });
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final course = filtered[index];
                                return CourseCard(
                                  course: course,
                                  animationIndex:
                                      _coursesHaveAnimated ? -1 : index,
                                  onTap: () => _showDetails(context, course),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        );
                      },
                      loading: () => SliverFillRemaining(
                        child: _LoadingGrid(tc: tc),
                      ),
                      error: (err, _) => SliverFillRemaining(
                        child: _ErrorState(
                            tc: tc,
                            onRetry: () => ref.invalidate(coursesProvider)),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(coursesProvider);
    setState(() {
      _lastRefreshTime = DateTime.now();
      _coursesHaveAnimated = false;
    });
  }

  List<Course> _filterCourses(List<Course> courses) {
    var list = courses.where((c) => c.isActive || c.isCompleted).toList();
    if (_selectedFilter == 'completed') {
      list = list.where((c) => c.isCompleted).toList();
    } else if (_selectedFilter != 'all') {
      list = list
          .where((c) => c.type == _selectedFilter && !c.isCompleted)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.description?.toLowerCase().contains(q) ?? false) ||
              (c.mosqueName?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  void _showDetails(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _CourseDetailsSheet(course: course),
      ),
    );
  }
}

// ─── Collapsible Header Delegate ──────────────────────────────────────────────
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final _TC tc;
  final dynamic user;
  final Animation<double> glow;
  final double collapseAmt;
  final VoidCallback onProfile;
  final VoidCallback? onRefresh;
  final VoidCallback onNotify;
  final bool isLoading;
  final double minHeight;
  final double maxHeight;

  const _HomeHeaderDelegate({
    required this.tc,
    required this.user,
    required this.glow,
    required this.collapseAmt,
    required this.onProfile,
    required this.onRefresh,
    required this.onNotify,
    required this.isLoading,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate old) =>
      old.collapseAmt != collapseAmt || old.isLoading != isLoading;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final expandedOpacity = (1 - progress * 2.5).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: glow,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tc.headerG1, tc.headerG2],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(_lerp(36, 0, progress)),
            bottomRight: Radius.circular(_lerp(36, 0, progress)),
          ),
          boxShadow: [
            BoxShadow(
              color: tc.gold.withOpacity(0.08 * glow.value),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (expandedOpacity > 0)
              Positioned.fill(
                child: Opacity(
                  opacity: expandedOpacity,
                  child: CustomPaint(painter: _HeaderPatternPainter(tc: tc)),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: minExtent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onProfile,
                          child: _AvatarButton(tc: tc, user: user, glow: glow),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('أهلاً وسهلاً',
                                  style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10,
                                      color: tc.gold.withOpacity(0.7))),
                              Text(
                                user?.name.split(' ').first ?? 'الطالب',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: _lerp(17, 14, progress),
                                  fontWeight: FontWeight.bold,
                                  color: tc.isDark
                                      ? const Color(0xFFF0E6C8)
                                      : Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _IconBtn(
                          tc: tc,
                          icon: isLoading
                              ? Icons.hourglass_top_rounded
                              : Icons.refresh_rounded,
                          onTap: isLoading ? null : onRefresh,
                          spinning: isLoading,
                        ),
                        _IconBtn(
                            tc: tc,
                            icon: Icons.notifications_outlined,
                            onTap: onNotify),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (expandedOpacity > 0)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Column(
                    children: [
                      Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            color: tc.gold.withOpacity(0.55 + 0.3 * glow.value),
                            letterSpacing: 1.2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text('اكتشف دورات حفظ القرآن الكريم',
                          style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: tc.gold.withOpacity(0.5)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

// ─── Avatar Button ────────────────────────────────────────────────────────────
class _AvatarButton extends StatelessWidget {
  final _TC tc;
  final dynamic user;
  final Animation<double> glow;
  const _AvatarButton(
      {required this.tc, required this.user, required this.glow});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (_, __) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              RadialGradient(colors: [tc.headerG1, const Color(0xFF071A14)]),
          border: Border.all(
            color: tc.gold.withOpacity(0.35 + 0.25 * glow.value),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tc.gold.withOpacity(0.15 * glow.value),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            user?.initials ?? 'م',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: tc.isDark ? const Color(0xFFF0E6C8) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatefulWidget {
  final _TC tc;
  final IconData icon;
  final VoidCallback? onTap;
  final bool spinning;
  const _IconBtn(
      {required this.tc,
      required this.icon,
      this.onTap,
      this.spinning = false});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn>
    with SingleTickerProviderStateMixin {
  AnimationController? _spinCtrl;
  Animation<double>? _spin;

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _startSpin();
  }

  @override
  void didUpdateWidget(covariant _IconBtn old) {
    super.didUpdateWidget(old);
    if (widget.spinning && _spinCtrl == null) _startSpin();
    if (!widget.spinning && _spinCtrl != null) _stopSpin();
  }

  void _startSpin() {
    _spinCtrl =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat();
    _spin = Tween<double>(begin: 0, end: 2 * math.pi).animate(_spinCtrl!);
  }

  void _stopSpin() {
    _spinCtrl?.dispose();
    _spinCtrl = null;
    _spin = null;
  }

  @override
  void dispose() {
    _spinCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(widget.icon,
        color: widget.onTap == null
            ? widget.tc.gold.withOpacity(0.3)
            : widget.tc.gold.withOpacity(0.7),
        size: 20);

    if (widget.spinning && _spin != null) {
      iconWidget = AnimatedBuilder(
        animation: _spin!,
        builder: (_, child) =>
            Transform.rotate(angle: _spin!.value, child: child),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.tc.gold.withOpacity(0.08),
        ),
        child: Center(child: iconWidget),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final _TC tc;
  final List<Course> courses;
  const _StatsRow({required this.tc, required this.courses});

  @override
  Widget build(BuildContext context) {
    final enrolled =
        courses.where((c) => c.isEnrolled && !c.isCompleted).length;
    final pending = courses.where((c) => c.isPending).length;
    final available = courses.where((c) => c.canEnroll && !c.isEnrolled).length;
    final completed = courses.where((c) => c.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _StatChip(
              tc: tc,
              label: 'مسجّل',
              value: enrolled,
              icon: Icons.school_outlined,
              color: tc.gold),
          const SizedBox(width: 8),
          _StatChip(
              tc: tc,
              label: 'متاحة',
              value: available,
              icon: Icons.explore_outlined,
              color: tc.success),
          const SizedBox(width: 8),
          _StatChip(
              tc: tc,
              label: 'مراجعة',
              value: pending,
              icon: Icons.schedule_rounded,
              color: tc.warning),
          const SizedBox(width: 8),
          _StatChip(
              tc: tc,
              label: 'منتهية',
              value: completed,
              icon: Icons.emoji_events_outlined,
              color: tc.mutedText),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final _TC tc;
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.tc,
      required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tc.goldBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text('$value',
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Tajawal', fontSize: 9, color: tc.mutedText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Gold Search Bar ──────────────────────────────────────────────────────────
class _GoldSearchBar extends StatelessWidget {
  final _TC tc;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _GoldSearchBar(
      {required this.tc, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: tc.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.goldBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
            fontFamily: 'Tajawal', fontSize: 13, color: tc.primaryText),
        cursorColor: tc.gold,
        decoration: InputDecoration(
          hintText: 'ابحث عن دورة...',
          hintStyle: TextStyle(
              fontFamily: 'Tajawal', fontSize: 12, color: tc.mutedText),
          prefixIcon: Icon(Icons.search_rounded, color: tc.goldDim, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: tc.goldDim, size: 16),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  })
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Gold Filter Row ──────────────────────────────────────────────────────────
class _GoldFilterRow extends StatelessWidget {
  final _TC tc;
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _GoldFilterRow(
      {required this.tc,
      required this.selectedFilter,
      required this.onChanged});

  static const _filters = [
    ('all', 'الكل', Icons.grid_view_rounded),
    ('online', 'عبر الإنترنت', Icons.wifi_rounded),
    ('open', 'مفتوحة', Icons.lock_open_rounded),
    ('closed', 'مغلقة', Icons.lock_rounded),
    ('completed', 'منتهية', Icons.emoji_events_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label, icon) = _filters[i];
          final selected = selectedFilter == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? tc.gold.withOpacity(0.12) : tc.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? tc.gold : tc.goldBorder,
                  width: selected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 13, color: selected ? tc.gold : tc.mutedText),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? tc.gold : tc.mutedText,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final _TC tc;
  final String query;
  const _EmptyState({required this.tc, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tc.goldFaint,
              border: Border.all(color: tc.goldBorder),
            ),
            child: Icon(
              query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.auto_stories_outlined,
              size: 36,
              color: tc.goldDim,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            query.isNotEmpty ? 'لا نتائج للبحث' : 'لا توجد دورات متاحة',
            style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tc.primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            query.isNotEmpty
                ? 'جرّب كلمة بحث مختلفة'
                : 'جرّب تغيير الفلتر أو تحديث الصفحة',
            style: TextStyle(
                fontFamily: 'Tajawal', fontSize: 12, color: tc.mutedText),
          ),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final _TC tc;
  final VoidCallback onRetry;
  const _ErrorState({required this.tc, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tc.error.withOpacity(0.08),
              border: Border.all(color: tc.error.withOpacity(0.25)),
            ),
            child: Icon(Icons.wifi_off_rounded, color: tc.error, size: 32),
          ),
          const SizedBox(height: 16),
          Text('تعذّر تحميل الدورات',
              style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: tc.primaryText)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tc.isDark
                      ? const [Color(0xFFC4973A), Color(0xFF8A5D1E)]
                      : const [Color(0xFFA8782A), Color(0xFF704E18)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Shimmer Grid ─────────────────────────────────────────────────────
class _LoadingGrid extends StatefulWidget {
  final _TC tc;
  const _LoadingGrid({required this.tc});

  @override
  State<_LoadingGrid> createState() => _LoadingGridState();
}

class _LoadingGridState extends State<_LoadingGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shim;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        duration: const Duration(milliseconds: 1600), vsync: this)
      ..repeat();
    _shim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, i) => _ShimmerCard(tc: widget.tc, shim: _shim.value),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final _TC tc;
  final double shim;
  const _ShimmerCard({required this.tc, required this.shim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.goldBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Colors.transparent,
              tc.gold.withOpacity(0.06),
              Colors.transparent,
            ],
            stops: [
              (shim - 0.5).clamp(0.0, 1.0),
              shim.clamp(0.0, 1.0),
              (shim + 0.5).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: Column(
            children: [
              Container(height: 112, color: tc.surface),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: tc.surface,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                            color: tc.surface,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Course Details Bottom Sheet ──────────────────────────────────────────────
class _CourseDetailsSheet extends ConsumerWidget {
  final Course course;
  const _CourseDetailsSheet({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = _TC.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: tc.goldBorder),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: tc.goldBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Banners ───────────────────────────────────────
                  if (course.isCompleted)
                    _StatusBanner(
                        tc: tc,
                        icon: Icons.emoji_events_rounded,
                        label:
                            'انتهت هذه الدورة${course.completedAt != null ? "  •  ${course.completedAtFormatted}" : ""}',
                        color: tc.gold),

                  if (!course.isCompleted && !course.isRegistrationOpen)
                    _StatusBanner(
                        tc: tc,
                        icon: Icons.lock_outline_rounded,
                        label: 'التسجيل في هذه الدورة مغلق حالياً',
                        color: tc.error),

                  if (!course.isCompleted &&
                      course.isRegistrationOpen &&
                      course.isFull)
                    _StatusBanner(
                        tc: tc,
                        icon: Icons.group_off_rounded,
                        label: 'اكتملت الأماكن المتاحة في هذه الدورة',
                        color: tc.warning),

                  if (course.isEnrolled && !course.isCompleted)
                    _StatusBanner(
                        tc: tc,
                        icon: course.isApproved
                            ? Icons.check_circle_outline_rounded
                            : Icons.schedule_rounded,
                        label: course.enrollmentStatusDisplayName,
                        color: course.isApproved ? tc.success : tc.warning),

                  // ── Course Title ─────────────────────────────────────────
                  Text(
                    course.name,
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tc.primaryText),
                  ),

                  const SizedBox(height: 10),

                  // ── Type badge (standalone, no mosque text here) ──────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tc.goldFaint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: tc.goldBorder),
                        ),
                        child: Text(course.typeDisplayName,
                            style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tc.gold)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Mosque Strip (the new creative section) ───────────────
                  if (course.mosque != null) ...[
                    _SheetSection(
                        tc: tc, title: 'المسجد', icon: Icons.mosque_rounded),
                    const SizedBox(height: 10),
                    _MosqueStrip(mosque: course.mosque!, tc: tc),
                    const SizedBox(height: 16),
                  ],

                  // ── Description ──────────────────────────────────────────
                  if (course.description != null) ...[
                    _SheetSection(
                        tc: tc,
                        title: 'وصف الدورة',
                        icon: Icons.description_outlined),
                    const SizedBox(height: 8),
                    Text(course.description!,
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: tc.primaryText,
                            height: 1.7)),
                    const SizedBox(height: 16),
                  ],

                  // ── Course Info ──────────────────────────────────────────
                  _SheetSection(
                      tc: tc,
                      title: 'معلومات الدورة',
                      icon: Icons.info_outline_rounded),
                  const SizedBox(height: 10),

                  _InfoRow(
                      tc: tc,
                      icon: Icons.people_outline_rounded,
                      label: 'عدد الطلاب',
                      value: '${course.currentStudents}/${course.maxStudents}'),
                  if (course.startDate != null)
                    _InfoRow(
                        tc: tc,
                        icon: Icons.calendar_today_outlined,
                        label: 'تاريخ البداية',
                        value:
                            '${course.startDate!.day}/${course.startDate!.month}/${course.startDate!.year}'),
                  if (course.endDate != null)
                    _InfoRow(
                        tc: tc,
                        icon: Icons.event_outlined,
                        label: 'تاريخ النهاية',
                        value:
                            '${course.endDate!.day}/${course.endDate!.month}/${course.endDate!.year}'),
                  if (course.isCompleted && course.completedAt != null)
                    _InfoRow(
                        tc: tc,
                        icon: Icons.verified_outlined,
                        label: 'تاريخ الانتهاء',
                        value: course.completedAtFormatted),
                  if (course.scheduleDetails != null)
                    _InfoRow(
                        tc: tc,
                        icon: Icons.schedule_outlined,
                        label: 'المواعيد',
                        value: course.scheduleDetails!),
                  if (course.requirements != null) ...[
                    const SizedBox(height: 16),
                    _SheetSection(
                        tc: tc,
                        title: 'المتطلبات',
                        icon: Icons.checklist_rounded),
                    const SizedBox(height: 8),
                    Text(course.requirements!,
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: tc.primaryText,
                            height: 1.7)),
                  ],
                ],
              ),
            ),
          ),

          // ── Enroll Button ──────────────────────────────────────────────
          if (!course.isEnrolled && course.canEnroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: () => _enroll(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tc.isDark
                          ? const [Color(0xFFC4973A), Color(0xFF8A5D1E)]
                          : const [Color(0xFFA8782A), Color(0xFF704E18)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: tc.gold.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Text('التسجيل في الدورة',
                      style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFF8E8)),
                      textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _enroll(BuildContext context, WidgetRef ref) async {
    try {
      final svc = ref.read(courseServiceProvider);
      await svc.enrollInCourse(course.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ref.invalidate(coursesProvider);
        final tc = _TC.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تم تقديم طلب التسجيل بنجاح',
              style: TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: tc.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        final tc = _TC.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل في التسجيل: $e',
              style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: tc.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

// ─── Mosque Strip ─────────────────────────────────────────────────────────────
// The "creative" mosque card shown inside the details sheet.
class _MosqueStrip extends StatelessWidget {
  final dynamic mosque; // your Mosque model
  final _TC tc;
  const _MosqueStrip({required this.mosque, required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.goldBorder),
        color: tc.goldFaint,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Top: image + name + address ──────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mosque thumbnail (square, 80px)
                SizedBox(
                  width: 80,
                  child: mosque.image_url != null
                      ? CachedNetworkImage(
                          imageUrl: mosque.image_url as String,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _MosqueFallbackThumb(tc: tc),
                        )
                      : _MosqueFallbackThumb(tc: tc),
                ),

                // Vertical gold divider
                Container(width: 1, color: tc.goldBorder),

                // Name + address
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mosque label pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tc.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tc.goldBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mosque_rounded,
                                  size: 10, color: tc.gold),
                              const SizedBox(width: 4),
                              Text('مسجد',
                                  style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 9,
                                      color: tc.gold,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mosque.name as String,
                          style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: tc.primaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((mosque.fullAddress as String).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12, color: tc.goldDim),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  mosque.fullAddress as String,
                                  style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 11,
                                      color: tc.mutedText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom: contact + map pills ──────────────────────────────────
          if ((mosque.hasContactInfo as bool) || (mosque.hasLocation as bool))
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tc.goldBorder)),
                color: tc.card.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (mosque.phone != null)
                    _MosquePill(
                      tc: tc,
                      icon: Icons.phone_outlined,
                      label: mosque.phone as String,
                    ),
                  if (mosque.phone != null && mosque.email != null)
                    const SizedBox(width: 8),
                  if (mosque.email != null)
                    Expanded(
                      child: _MosquePill(
                        tc: tc,
                        icon: Icons.email_outlined,
                        label: mosque.email as String,
                      ),
                    ),
                  if ((mosque.hasContactInfo as bool) &&
                      (mosque.hasLocation as bool))
                    const SizedBox(width: 8),
                  if (mosque.hasLocation as bool)
                    _MosquePill(
                      tc: tc,
                      icon: Icons.map_outlined,
                      label: 'خريطة',
                      isAccent: true,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MosqueFallbackThumb extends StatelessWidget {
  final _TC tc;
  const _MosqueFallbackThumb({required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tc.gold.withOpacity(0.08),
      child: Center(
        child: Icon(Icons.mosque_rounded, size: 28, color: tc.goldDim),
      ),
    );
  }
}

class _MosquePill extends StatelessWidget {
  final _TC tc;
  final IconData icon;
  final String label;
  final bool isAccent;
  const _MosquePill({
    required this.tc,
    required this.icon,
    required this.label,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent ? tc.gold.withOpacity(0.12) : tc.goldFaint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isAccent ? tc.gold.withOpacity(0.4) : tc.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isAccent ? tc.gold : tc.goldDim),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: isAccent ? tc.gold : tc.mutedText,
                  fontWeight: isAccent ? FontWeight.w700 : FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet Components ─────────────────────────────────────────────────────────
class _SheetPlaceholder extends StatelessWidget {
  final _TC tc;
  const _SheetPlaceholder({required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tc.headerG1, const Color(0xFF071A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(Icons.menu_book_rounded,
            size: 50, color: tc.gold.withOpacity(0.5)),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final _TC tc;
  final IconData icon;
  final String label;
  final Color color;
  const _StatusBanner(
      {required this.tc,
      required this.icon,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color))),
        ],
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final _TC tc;
  final String title;
  final IconData icon;
  const _SheetSection(
      {required this.tc, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: tc.gold, size: 14),
        const SizedBox(width: 7),
        Text(title,
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tc.primaryText)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tc.goldBorder, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Updated _InfoRow now includes an icon for visual polish
class _InfoRow extends StatelessWidget {
  final _TC tc;
  final String label, value;
  final IconData icon;
  const _InfoRow(
      {required this.tc,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: tc.goldDim),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Tajawal', fontSize: 12, color: tc.mutedText)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: tc.primaryText,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Background Painters ──────────────────────────────────────────────────────
class _HomeBgPainter extends StatelessWidget {
  final _TC tc;
  const _HomeBgPainter({required this.tc});

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
      ..color = tc.gold.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    _star(canvas, Offset(size.width + 20, size.height * 0.3), 100, paint);
    _star(canvas, Offset(-20, size.height * 0.65), 80, paint);
    _star(canvas, Offset(size.width * 0.5, size.height + 30), 70, paint);
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
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

class _HeaderPatternPainter extends CustomPainter {
  final _TC tc;
  const _HeaderPatternPainter({required this.tc});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tc.gold.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final cx = size.width * 0.88, cy = size.height * 0.3, r = 70.0;
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
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.3), r + 12,
        paint..color = tc.gold.withOpacity(0.04));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
