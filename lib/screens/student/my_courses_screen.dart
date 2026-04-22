// Path: lib/presentation/screens/student/my_courses_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../widgets/course_card.dart'; // سنستخدم CompactCourseCard من هذا الملف

// ─── Adaptive Theme Colors (نفس الألوان المستخدمة في التطبيق) ──────────────
class _TC {
  final bool isDark;
  const _TC(this.isDark);
  factory _TC.of(BuildContext ctx) =>
      _TC(Theme.of(ctx).brightness == Brightness.dark);

  Color get bg => isDark ? const Color(0xFF071A14) : const Color(0xFFF5F0E6);
  Color get card => isDark ? const Color(0xFF0C1E16) : Colors.white;
  Color get gold => isDark ? const Color(0xFFC4973A) : const Color(0xFF9B7520);
  Color get goldFaint =>
      isDark ? const Color(0x18C4973A) : const Color(0x14A8782A);
  Color get goldBorder =>
      isDark ? const Color(0x33C4973A) : const Color(0x55A8782A);
  Color get primaryText =>
      isDark ? const Color(0xFFF0E6C8) : const Color(0xFF1C2B1F);
  Color get mutedText =>
      isDark ? const Color(0x77F0E6C8) : const Color(0x88284030);
}

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen>
    with WidgetsBindingObserver {
  String _selectedFilter = 'active';
  final List<String> _filters = ['active', 'completed', 'pending'];
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastRefreshTime != null &&
          DateTime.now().difference(_lastRefreshTime!) >
              const Duration(minutes: 5)) {
        _refreshData();
      }
    }
  }

  Future<void> _refreshData() async {
    ref.invalidate(myCoursesProvider);
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
  }

  List<Course> _filterCourses(List<Course> courses) {
    switch (_selectedFilter) {
      case 'active':
        // الدورات النشطة والمقبولة التي لم تنتهِ بعد
        return courses
            .where((course) => !course.isCompleted && course.isApproved)
            .toList();
      case 'completed':
        return courses.where((course) => course.isCompleted).toList();
      case 'pending':
        return courses.where((course) => course.isPending).toList();
      default:
        return courses;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'active':
        return 'نشطة';
      case 'completed':
        return 'مكتملة';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return filter;
    }
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'active':
        return 'ليس لديك أي دورات نشطة حالياً';
      case 'completed':
        return 'لم تكمل أي دورات بعد';
      case 'pending':
        return 'ليس لديك أي طلبات تسجيل معلقة';
      default:
        return 'لم تنضم لأي دورات بعد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC.of(context);
    final myCoursesAsync = ref.watch(myCoursesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: tc.bg,
        appBar: AppBar(
          backgroundColor: tc.bg,
          elevation: 0,
          title: Text(
            'دوراتي',
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
              onPressed: myCoursesAsync.isLoading ? null : _refreshData,
              icon: myCoursesAsync.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(tc.gold),
                      ),
                    )
                  : Icon(Icons.refresh_rounded, color: tc.gold),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: myCoursesAsync.when(
          data: (courses) {
            final filteredCourses = _filterCourses(courses);

            return RefreshIndicator(
              color: tc.gold,
              backgroundColor: tc.card,
              onRefresh: _refreshData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Filter chips ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return ChoiceChip(
                            label: Text(
                              _getFilterLabel(filter),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? tc.gold : tc.mutedText,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedFilter = filter);
                            },
                            backgroundColor: tc.card,
                            selectedColor: tc.gold.withOpacity(0.15),
                            side: BorderSide(
                              color: isSelected ? tc.gold : tc.goldBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // ── Courses list ──
                  if (filteredCourses.isNotEmpty) ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = filteredCourses[index];
                          // قم بإرجاع CompactCourseCard مباشرة بدون Padding
                          return CompactCourseCard(
                            course: course,
                            onTap: () {
                              // context.go('/course-details', extra: course);
                            },
                          );
                        },
                        childCount: filteredCourses.length,
                      ),
                    ),
                  ] else ...[
                    // ── Empty State ──
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tc.goldFaint,
                                border: Border.all(color: tc.goldBorder),
                              ),
                              child: Icon(
                                Icons.auto_stories_outlined,
                                size: 48,
                                color: tc.gold.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _getEmptyMessage(),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tc.primaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Bottom spacing ──
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: tc.gold),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل الدورات',
                  style: TextStyle(
                      fontFamily: 'Amiri', fontSize: 18, color: tc.primaryText),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Tajawal')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.gold,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
