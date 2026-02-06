import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/course_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chips.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  DateTime? _lastRefreshTime;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).user;
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coursesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.surface,
                elevation: 0,
                title: Row(
                  children: [
                    // Profile Avatar
                    GestureDetector(
                      onTap: () => context.go('/student/profile'),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.initials ?? 'م',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Welcome Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أهلاً وسهلاً',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                          Text(
                            user?.name.split(' ').first ?? 'الطالب',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
// Refresh Button
                    IconButton(
                      onPressed: coursesAsync.isLoading ? null : _refreshData,
                      icon: coursesAsync.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      color: AppColors.onSurface,
                      tooltip: 'تحديث',
                    ),
                    // Notifications
                    IconButton(
                      onPressed: () {
                        // TODO: Navigate to notifications
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الإشعارات قريباً')),
                        );
                      },
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.onSurface,
                    ),
                  ],
                ),
              ),

              // Search and Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      SearchBarWidget(
                        controller: _searchController,
                        hint: 'ابحث عن الدورات...',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Filter Chips
                      FilterChips(
                        selectedFilter: _selectedFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        filters: const [
                          FilterOption('all', 'الكل'),
                          FilterOption('online', 'عبر الإنترنت'),
                          FilterOption('open', 'مفتوحة'),
                          FilterOption('closed', 'مغلقة'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Last Updated Info
              if (_lastRefreshTime != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'آخر تحديث: ${_formatRefreshTime(_lastRefreshTime!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Courses Grid
              coursesAsync.when(
                data: (courses) {
                  final filteredCourses = _filterCourses(courses);

                  if (filteredCourses.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد دورات متاحة',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرب تغيير المرشحات أو البحث',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = filteredCourses[index];
                          return CourseCard(
                            course: course,
                            onTap: () => _showCourseDetails(context, course),
                          );
                        },
                        childCount: filteredCourses.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(coursesProvider);
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(coursesProvider);
    _lastRefreshTime = DateTime.now();
  }

  // Auto-refresh when app comes to foreground
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

  List<Course> _filterCourses(List<Course> courses) {
    var filtered = courses.where((course) => course.isActive).toList();

    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered =
          filtered.where((course) => course.type == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) {
        return course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (course.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (course.mosqueName
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);
      }).toList();
    }

    return filtered;
  }

  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'منذ لحظات';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  void _showCourseDetails(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourseDetailsBottomSheet(course: course),
    );
  }
}

class CourseDetailsBottomSheet extends ConsumerWidget {
  final Course course;

  const CourseDetailsBottomSheet({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Image
                  if (course.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        course.imagePath!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: AppColors.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Course Title
                  Text(
                    course.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  // Course Type and Mosque
                  Row(
                    children: [
                      Chip(
                        label: Text(course.typeDisplayName),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      if (course.mosqueName != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  course.mosqueName!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (course.description != null) ...[
                    Text(
                      'وصف الدورة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Course Info
                  _buildInfoSection(context, 'معلومات الدورة', [
                    if (course.startDate != null)
                      _buildInfoRow(context, 'تاريخ البداية',
                          '${course.startDate!.day}/${course.startDate!.month}/${course.startDate!.year}'),
                    if (course.endDate != null)
                      _buildInfoRow(context, 'تاريخ النهاية',
                          '${course.endDate!.day}/${course.endDate!.month}/${course.endDate!.year}'),
                    _buildInfoRow(context, 'عدد الطلاب',
                        '${course.currentStudents}/${course.maxStudents}'),
                    if (course.scheduleDetails != null)
                      _buildInfoRow(
                          context, 'المواعيد', course.scheduleDetails!),
                  ]),

                  const SizedBox(height: 16),

                  // Requirements
                  if (course.requirements != null) ...[
                    _buildInfoSection(context, 'المتطلبات', [
                      Text(
                        course.requirements!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Enrollment Status
                  if (course.isEnrolled) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: course.isApproved
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: course.isApproved
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            course.isApproved
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            color: course.isApproved
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.enrollmentStatusDisplayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: course.isApproved
                                            ? AppColors.success
                                            : AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (course.isPending)
                                  Text(
                                    'سيتم إشعارك عند الموافقة على طلبك',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Action Button
          if (!course.isEnrolled && course.canEnroll)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _enrollInCourse(context, ref),
                  child: const Text('التسجيل في الدورة'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollInCourse(BuildContext context, WidgetRef ref) async {
    try {
      final courseService = ref.read(courseServiceProvider);
      await courseService.enrollInCourse(course.id);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تقديم طلب التسجيل بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(coursesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في التسجيل: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
