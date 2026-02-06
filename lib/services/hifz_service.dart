import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/hifz_log.dart';
import '../models/hifz_statistics.dart';
import 'api_service.dart';

class HifzService {
  final ApiService _apiService;

  HifzService(this._apiService);

  // Get all hifz logs for the student
  Future<List<HifzLog>> getMyLogs() async {
    try {
      final response = await _apiService.get('/hifz/my-logs');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => HifzLog.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('فشل في تحميل سجلات الحفظ: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // Get hifz logs for a specific course
  Future<List<HifzLog>> getMyLogsByCourse(int courseId) async {
    try {
      final response = await _apiService.get('/hifz/my-logs/$courseId');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => HifzLog.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('فشل في تحميل سجلات الدورة: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // Get progress summary by course
  Future<List<CourseProgress>> getMyProgress() async {
    try {
      final response = await _apiService.get('/hifz/my-progress');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => CourseProgress.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('فشل في تحميل التقدم: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // Get overall statistics
  Future<HifzStatistics> getMyStatistics() async {
    try {
      final response = await _apiService.get('/hifz/my-statistics');

      // Also get logs to calculate additional statistics
      final logsResponse = await _apiService.get('/hifz/my-logs');
      final logs = (logsResponse.data as List)
          .map((json) => HifzLog.fromJson(json))
          .toList();

      // Calculate total ayahs and average evaluation from logs
      int totalAyahs = 0;
      double totalEvaluation = 0;

      for (var log in logs) {
        // Calculate ayahs in this log
        // Note: This is simplified - you might need to account for different surahs
        int ayahsInLog = 0;
        if (log.startSura == log.endSura) {
          ayahsInLog = log.endAyah - log.startAyah + 1;
        } else {
          // For multiple surahs, this is an approximation
          ayahsInLog = log.endAyah + (log.endSura - log.startSura) * 100;
        }
        totalAyahs += ayahsInLog;

        // Get evaluation score
        int evalScore = 0;
        switch (log.evaluation) {
          case 'excellent':
            evalScore = 5;
            break;
          case 'very_good':
            evalScore = 4;
            break;
          case 'good':
            evalScore = 3;
            break;
          case 'needs_improvement':
            evalScore = 2;
            break;
          case 'poor':
            evalScore = 1;
            break;
        }
        totalEvaluation += evalScore;
      }

      final avgEvaluation =
          logs.isNotEmpty ? totalEvaluation / logs.length : 0.0;

      final stats = HifzStatistics.fromJson(response.data);

      // Return stats with additional calculated values
      return HifzStatistics(
        averagePages: stats.averagePages,
        maxPages: stats.maxPages,
        minPages: stats.minPages,
        totalSessions: stats.totalSessions,
        totalAyahs: totalAyahs,
        averageEvaluation: avgEvaluation,
      );
    } on DioException catch (e) {
      throw Exception('فشل في تحميل الإحصائيات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

// Providers
final hifzServiceProvider = Provider<HifzService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return HifzService(apiService);
});

// Statistics Provider
final hifzStatisticsProvider = FutureProvider<HifzStatistics>((ref) async {
  final hifzService = ref.watch(hifzServiceProvider);
  return await hifzService.getMyStatistics();
});

// Progress Provider
final hifzProgressProvider = FutureProvider<List<CourseProgress>>((ref) async {
  final hifzService = ref.watch(hifzServiceProvider);
  return await hifzService.getMyProgress();
});

// All Logs Provider
final myHifzLogsProvider = FutureProvider<List<HifzLog>>((ref) async {
  final hifzService = ref.watch(hifzServiceProvider);
  return await hifzService.getMyLogs();
});

// Logs by Course Provider
final hifzLogsByCourseProvider =
    FutureProvider.family<List<HifzLog>, int>((ref, courseId) async {
  final hifzService = ref.watch(hifzServiceProvider);
  return await hifzService.getMyLogsByCourse(courseId);
});
