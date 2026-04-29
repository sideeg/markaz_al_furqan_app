// Path: lib/services/hifz_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/hifz_log.dart';
import '../models/hifz_statistics.dart';
import 'api_service.dart';

// ─── CourseProgress Model ─────────────────────────────────────────────────────
// Maps from /hifz/my-progress → data: [{ course_id, course_name, sessions_count,
//                                         total_ayahs, evaluation_percent }]
class CourseProgress {
  final int courseId;
  final String? courseName;
  final int? sessionsCount;
  final int? totalAyahs;
  final double? evaluationPercent; // 0–100

  const CourseProgress({
    required this.courseId,
    this.courseName,
    this.sessionsCount,
    this.totalAyahs,
    this.evaluationPercent,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: (json['course_id'] as num? ?? 0).toInt(),
      courseName: json['course_name'] as String?,
      sessionsCount: (json['sessions_count'] as num? ?? 0).toInt(),
      totalAyahs: (json['total_ayahs'] as num? ?? 0).toInt(),
      evaluationPercent: (json['evaluation_percent'] as num? ?? 0.0).toDouble(),
    );
  }
}

// ─── HifzService ──────────────────────────────────────────────────────────────
class HifzService {
  final ApiService _apiService;

  HifzService(this._apiService);

  // ── Get all hifz logs ──────────────────────────────────────────────────────
  // Backend: GET /hifz/my-logs → returns a plain JSON array (no success wrapper)
  Future<List<HifzLog>> getMyLogs() async {
    try {
      final response = await _apiService.get('/hifz/my-logs');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => HifzLog.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('فشل في تحميل سجلات الحفظ: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // ── Get hifz logs for a specific course ───────────────────────────────────
  // Backend: GET /hifz/my-logs/{course} → plain array
  Future<List<HifzLog>> getMyLogsByCourse(int courseId) async {
    try {
      final response = await _apiService.get('/hifz/my-logs/$courseId');
      if (response.data is List) {
        return (response.data as List)
            .map((json) => HifzLog.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('فشل في تحميل سجلات الدورة: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // ── Get progress summary grouped by course ─────────────────────────────────
  // Backend: GET /hifz/my-progress → { success: true, data: [...] }
  Future<List<CourseProgress>> getMyProgress() async {
    try {
      final response = await _apiService.get('/hifz/my-progress');
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map(
                (json) => CourseProgress.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('فشل في تحميل التقدم: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // ── Get overall statistics ─────────────────────────────────────────────────
  // Backend: GET /hifz/my-statistics → { success: true, data: { ... } }
  // All calculations are done server-side — no local computation needed.
  Future<HifzStatistics> getMyStatistics() async {
    try {
      final response = await _apiService.get('/hifz/my-statistics');
      if (response.data['success'] == true) {
        return HifzStatistics.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw Exception(response.data['message'] ?? 'فشل في تحميل الإحصائيات');
    } on DioException catch (e) {
      throw Exception('فشل في تحميل الإحصائيات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final hifzServiceProvider = Provider<HifzService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return HifzService(apiService);
});

final hifzStatisticsProvider = FutureProvider<HifzStatistics>((ref) async {
  return ref.watch(hifzServiceProvider).getMyStatistics();
});

final hifzProgressProvider = FutureProvider<List<CourseProgress>>((ref) async {
  return ref.watch(hifzServiceProvider).getMyProgress();
});

final myHifzLogsProvider = FutureProvider<List<HifzLog>>((ref) async {
  return ref.watch(hifzServiceProvider).getMyLogs();
});

final hifzLogsByCourseProvider =
    FutureProvider.family<List<HifzLog>, int>((ref, courseId) async {
  return ref.watch(hifzServiceProvider).getMyLogsByCourse(courseId);
});
