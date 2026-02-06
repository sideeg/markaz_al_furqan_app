import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../widgets/course_card.dart';
import '../../widgets/section_header.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  String _selectedFilter = 'active';
  final List<String> _filters = ['active', 'completed', 'pending'];
  DateTime? _lastRefreshTime;

  @override
  Widget build(BuildContext context) {
    final myCoursesAsync = ref.watch(myCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دوراتي'),
        centerTitle: true,
        actions: [
          // Refresh Button
          IconButton(
            onPressed: myCoursesAsync.isLoading ? null : _refreshData,
            icon: myCoursesAsync.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: myCoursesAsync.when(
        data: (courses) {
          final filteredCourses = _filterCourses(courses);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myCoursesProvider),
            child: CustomScrollView(
              slivers: [
                // Filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: _filters.map((filter) {
                        return ChoiceChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) => setState(() =>
                              _selectedFilter = selected ? filter : 'active'),
                          backgroundColor: AppColors.surfaceVariant,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          labelStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _selectedFilter == filter
                                        ? AppColors.primary
                                        : AppColors.onSurface,
                                  ),
                        );
                      }).toList(),
                    ),
                    // Last Updated Info
                  ),
                ),

                // Active courses
                if (filteredCourses.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: _getSectionTitle(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = filteredCourses[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: CourseCard(
                            course: course,
                          ),
                        );
                      },
                      childCount: filteredCourses.length,
                    ),
                  ),
                ] else ...[
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyMessage(),
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Bottom spacing
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل الدورات',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myCoursesProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Auto-refresh when screen comes to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh if more than 5 minutes have passed
      if (_lastRefreshTime != null &&
          DateTime.now().difference(_lastRefreshTime!) >
              const Duration(minutes: 5)) {
        _refreshData();
      }
    }
  }

  Future<void> _refreshData() async {
    ref.invalidate(myCoursesProvider);
    _lastRefreshTime = DateTime.now();
  }

  List<Course> _filterCourses(List<Course> courses) {
    switch (_selectedFilter) {
      case 'active':
        return courses
            .where((course) => course.isActive && course.isApproved)
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

  String _getSectionTitle() {
    switch (_selectedFilter) {
      case 'active':
        return 'الدورات النشطة';
      case 'completed':
        return 'الدورات المكتملة';
      case 'pending':
        return 'طلبات التسجيل المعلقة';
      default:
        return 'دوراتي';
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
}
