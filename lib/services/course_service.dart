import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/course.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class CourseService {
  final ApiService _apiService;
  final StorageService _storageService;
  final Ref _ref;
  CourseService(this._apiService, this._storageService, this._ref);
  // ── Helper method to check version ──
  void _checkAppVersion(Map<String, dynamic> responseData) {
    final minVersion = responseData['minimum_required_version'];
    if (minVersion != null && minVersion is String) {
      // إرسال الرقم الجديد للـ AuthState ليحفظه ويقارنه
      Future.microtask(() {
        _ref
            .read(authServiceProvider.notifier)
            .updateMinimumVersion(minVersion);
      });
    }
  }

  // Get all available courses
  Future<List<Course>> getCourses({
    String? type,
    String? search,
    int? mosqueId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (type != null && type != 'all') {
        queryParams['type'] = type;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (mosqueId != null) {
        queryParams['mosque_id'] = mosqueId;
      }

      final response =
          await _apiService.get('/courses', queryParameters: queryParams);

      if (response.data['success'] == true) {
        _checkAppVersion(response.data);
        final coursesData = response.data['data'] as List;
        final courses = coursesData
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();

        // Cache courses locally
        await _storageService.saveCourses(courses);

        return courses;
      } else {
        throw Exception(response.data['message'] ?? 'فشل في تحميل الدورات');
      }
    } on DioException catch (e) {
      // Try to load from cache if network fails
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cachedCourses = await _storageService.getCourses();
        if (cachedCourses.isNotEmpty) {
          return cachedCourses;
        }
      }
      throw Exception('فشل في الاتصال بالخادم');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Get student's enrolled courses
  Future<List<Course>> getMyCourses() async {
    try {
      final response = await _apiService.get('/my-courses');

      if (response.data['success'] == true) {
        _checkAppVersion(response.data);
        final coursesData = response.data['data'] as List;
        final courses = coursesData
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();

        return courses;
      } else {
        throw Exception(response.data['message'] ?? 'فشل في تحميل دوراتي');
      }
    } on DioException catch (e) {
      // Try to load enrolled courses from cache
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final enrolledCourses = await _storageService.getEnrolledCourses();
        return enrolledCourses;
      }
      throw Exception('فشل في الاتصال بالخادم');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Get course details by ID
  Future<Course> getCourseDetails(int courseId) async {
    try {
      final response = await _apiService.get('/courses/$courseId');

      if (response.data['success'] == true) {
        final courseData = response.data['data'];
        final course = Course.fromJson(courseData);

        // Cache course locally
        await _storageService.saveCourse(course);

        return course;
      } else {
        throw Exception(
            response.data['message'] ?? 'فشل في تحميل تفاصيل الدورة');
      }
    } on DioException catch (e) {
      // Try to load from cache
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final cachedCourse = await _storageService.getCourse(courseId);
        if (cachedCourse != null) {
          return cachedCourse;
        }
      }
      throw Exception('فشل في الاتصال بالخادم');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Enroll in a course
  Future<void> enrollInCourse(int courseId, {String? notes}) async {
    try {
      final data = <String, dynamic>{};
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      final response =
          await _apiService.post('/courses/$courseId/enroll', data: data);

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'فشل في التسجيل في الدورة');
      }
    } on DioException catch (e) {
      String errorMessage = 'فشل في الاتصال بالخادم';

      if (e.response?.statusCode == 422) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'أنت مسجل في هذه الدورة بالفعل';
      } else if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Withdraw from a course
  Future<void> withdrawFromCourse(int courseId) async {
    try {
      final response = await _apiService.delete('/courses/$courseId/withdraw');

      if (response.data['success'] != true) {
        throw Exception(
            response.data['message'] ?? 'فشل في الانسحاب من الدورة');
      }
    } on DioException catch (e) {
      String errorMessage = 'فشل في الاتصال بالخادم';

      if (e.response?.data != null) {
        errorMessage = e.response!.data['message'] ?? errorMessage;
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Get student's progress in a course
  Future<Map<String, dynamic>> getCourseProgress(int courseId) async {
    try {
      final response = await _apiService.get('/my-progress/$courseId');

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'فشل في تحميل التقدم');
      }
    } on DioException catch (e) {
      throw Exception('فشل في الاتصال بالخادم');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Get student's evaluations for a course
  Future<List<Map<String, dynamic>>> getCourseEvaluations(int courseId) async {
    try {
      final response = await _apiService.get('/my-evaluations/$courseId');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'فشل في تحميل التقييمات');
      }
    } on DioException catch (e) {
      throw Exception('فشل في الاتصال بالخادم');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Search courses
  Future<List<Course>> searchCourses(String query) async {
    if (query.isEmpty) {
      return getCourses();
    }

    try {
      // First try online search
      return await getCourses(search: query);
    } catch (e) {
      // Fallback to local search
      return await _storageService.searchCourses(query);
    }
  }

  // Get courses by type
  Future<List<Course>> getCoursesByType(String type) async {
    return getCourses(type: type);
  }

  // Get featured courses
  Future<List<Course>> getFeaturedCourses() async {
    try {
      final response = await _apiService.get('/courses/featured');

      if (response.data['success'] == true) {
        final coursesData = response.data['data'] as List;
        return coursesData
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();
      } else {
        throw Exception(
            response.data['message'] ?? 'فشل في تحميل الدورات المميزة');
      }
    } catch (e) {
      // Fallback to regular courses
      final allCourses = await getCourses();
      return allCourses.take(5).toList(); // Return first 5 as featured
    }
  }

  // Get course statistics
  Future<Map<String, dynamic>> getCourseStats(int courseId) async {
    try {
      final response = await _apiService.get('/courses/$courseId/stats');

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(
            response.data['message'] ?? 'فشل في تحميل إحصائيات الدورة');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    await _storageService.clearCache();
  }

  // Sync with server
  Future<void> syncCourses() async {
    try {
      final courses = await getCourses();
      await _storageService.saveCourses(courses);
      await _storageService.updateLastSyncTime();
    } catch (e) {
      throw Exception('فشل في مزامنة البيانات: ${e.toString()}');
    }
  }
}

// Providers
final courseServiceProvider = Provider<CourseService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  // تمرير الـ ref هنا
  return CourseService(apiService, storageService, ref);
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourses();
});

final myCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getMyCourses();
});

final courseDetailsProvider =
    FutureProvider.family<Course, int>((ref, courseId) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourseDetails(courseId);
});

final courseProgressProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, courseId) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourseProgress(courseId);
});

final courseEvaluationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>(
        (ref, courseId) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getCourseEvaluations(courseId);
});

final featuredCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final courseService = ref.watch(courseServiceProvider);
  return courseService.getFeaturedCourses();
});
