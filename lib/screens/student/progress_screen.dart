import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../constants/app_colors.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/hifz_service.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final myCoursesAsync = ref.watch(myCoursesProvider);
    final statisticsAsync = ref.watch(hifzStatisticsProvider);
    final progressAsync = ref.watch(hifzProgressProvider);

    // Filter completed courses for the statistics card [cite: 5, 60]
    final completedCourses = myCoursesAsync.valueOrNull
            ?.where((course) => course.isCompleted)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقدمي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(hifzStatisticsProvider);
              ref.refresh(hifzProgressProvider);
              ref.refresh(myHifzLogsProvider);
            },
          ),
        ],
      ),
      body: statisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
        data: (statistics) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(hifzStatisticsProvider);
              ref.refresh(hifzProgressProvider);
              ref.refresh(myHifzLogsProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'نظرة عامة'),
                  const SizedBox(height: 16),

                  // Summary Cards [cite: 7, 62]
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: completedCourses.length.toString(),
                          label: 'الدورات المكتملة',
                          icon: Icons.school_outlined,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          value: statistics.totalAyahs.toString(),
                          label: 'الآيات المحفوظة',
                          icon: Icons.book_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: '${statistics.evaluationPercentage}%',
                          label: 'متوسط التقييم',
                          icon: Icons.star_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          value: statistics.totalSessions.toString(),
                          label: 'عدد الجلسات',
                          icon: Icons.timer_outlined,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Progress chart by course [cite: 8, 63]
                  progressAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const SizedBox.shrink(),
                    data: (progressList) {
                      if (progressList.isEmpty) return _buildNoDataCard();

                      final courses = myCoursesAsync.valueOrNull ?? [];
                      final chartData = progressList.map((progress) {
                        final course = courses.firstWhere(
                          (c) => c.id == progress.courseId,
                          orElse: () => Course(
                            id: progress.courseId,
                            name: 'دورة ${progress.courseId}',
                            description: '',
                            type: 'online',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        return {
                          'course': course.name.length > 15
                              ? '${course.name.substring(0, 15)}...'
                              : course.name,
                          'pages': progress.totalPages,
                        };
                      }).toList();

                      return _buildChartSection(chartData);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Activity statistics details [cite: 12, 67]
                  const SectionHeader(title: 'إحصائيات النشاط'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildActivityRow('متوسط الصفحات',
                            '${statistics.averagePages.toStringAsFixed(1)} صفحة'),
                        const Divider(height: 24),
                        _buildActivityRow(
                            'أعلى عدد صفحات', '${statistics.maxPages} صفحة'),
                        const Divider(height: 24),
                        _buildActivityRow('إجمالي الجلسات',
                            '${statistics.totalSessions} جلسة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> chartData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'تقدم الحفظ بالدورات'),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries>[
              BarSeries<Map<String, dynamic>, String>(
                dataSource: chartData,
                xValueMapper: (data, _) => data['course'],
                yValueMapper: (data, _) => data['pages'],
                name: 'الصفحات',
                color: AppColors.primary,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(String period, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(period, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('حدث خطأ في تحميل البيانات'),
          Text(error.toString(), style: Theme.of(context).textTheme.bodySmall),
          ElevatedButton(
            onPressed: () => ref.refresh(hifzStatisticsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('لا توجد بيانات حفظ حتى الآن')),
      ),
    );
  }
}
