import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/hifz_log.dart';
import '../models/mosque.dart';

class StorageService {
  static late Box<User> _userBox;
  static late Box<Course> _courseBox;
  static late Box<HifzLog> _hifzLogBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CourseAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HifzLogAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MosqueAdapter());
    }
    // Hive.registerAdapter(CourseAdapter());
    // Hive.registerAdapter(MosqueAdapter());

    // Open boxes
    _userBox = await Hive.openBox<User>('users');
    _courseBox = await Hive.openBox<Course>('courses');
    _hifzLogBox = await Hive.openBox<HifzLog>('hifz_logs');
    _settingsBox = await Hive.openBox('settings');
  }

  // User operations
  Future<void> saveUser(User user) async {
    await _userBox.put('current_user', user);
  }

  Future<User?> getUser() async {
    return _userBox.get('current_user');
  }

  Future<void> clearUser() async {
    await _userBox.delete('current_user');
  }

  // Course operations
  Future<void> saveCourses(List<Course> courses) async {
    await _courseBox.clear();
    for (final course in courses) {
      await _courseBox.put(course.id, course);
    }
  }

  Future<List<Course>> getCourses() async {
    return _courseBox.values.toList();
  }

  Future<Course?> getCourse(int id) async {
    return _courseBox.get(id);
  }

  Future<void> saveCourse(Course course) async {
    await _courseBox.put(course.id, course);
  }

  Future<void> deleteCourse(int id) async {
    await _courseBox.delete(id);
  }

  Future<List<Course>> getEnrolledCourses() async {
    return _courseBox.values.where((course) => course.isEnrolled).toList();
  }

  // Hifz Log operations
  Future<void> saveHifzLogs(List<HifzLog> logs) async {
    await _hifzLogBox.clear();
    for (final log in logs) {
      await _hifzLogBox.put(log.id, log);
    }
  }

  Future<List<HifzLog>> getHifzLogs() async {
    return _hifzLogBox.values.toList();
  }

  Future<HifzLog?> getHifzLog(int id) async {
    return _hifzLogBox.get(id);
  }

  Future<void> saveHifzLog(HifzLog log) async {
    await _hifzLogBox.put(log.id, log);
  }

  Future<void> deleteHifzLog(int id) async {
    await _hifzLogBox.delete(id);
  }

  Future<List<HifzLog>> getStudentHifzLogs(int studentId) async {
    return _hifzLogBox.values
        .where((log) => log.studentId == studentId)
        .toList();
  }

  Future<List<HifzLog>> getCourseHifzLogs(int courseId) async {
    return _hifzLogBox.values.where((log) => log.courseId == courseId).toList();
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }

  // Theme settings
  Future<void> saveThemeMode(String themeMode) async {
    await saveSetting('theme_mode', themeMode);
  }

  String getThemeMode() {
    return getSetting('theme_mode', defaultValue: 'light') ?? 'light';
  }

  // Language settings
  Future<void> saveLanguage(String language) async {
    await saveSetting('language', language);
  }

  String getLanguage() {
    return getSetting('language', defaultValue: 'ar') ?? 'ar';
  }

  // Notification settings
  Future<void> saveNotificationEnabled(bool enabled) async {
    await saveSetting('notifications_enabled', enabled);
  }

  bool getNotificationEnabled() {
    return getSetting('notifications_enabled', defaultValue: true) ?? true;
  }

  // Cache management
  Future<void> clearCache() async {
    await _courseBox.clear();
    await _hifzLogBox.clear();
  }

  Future<void> clearAllData() async {
    await _userBox.clear();
    await _courseBox.clear();
    await _hifzLogBox.clear();
    await _settingsBox.clear();
  }

  // Data synchronization helpers
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = getSetting<int>('last_sync_time');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> updateLastSyncTime() async {
    await saveSetting('last_sync_time', DateTime.now().millisecondsSinceEpoch);
  }

  // Offline data management
  Future<bool> hasOfflineData() async {
    return _courseBox.isNotEmpty || _hifzLogBox.isNotEmpty;
  }

  Future<Map<String, int>> getDataCounts() async {
    return {
      'courses': _courseBox.length,
      'hifz_logs': _hifzLogBox.length,
    };
  }

  // Search functionality
  Future<List<Course>> searchCourses(String query) async {
    final courses = await getCourses();
    return courses.where((course) {
      return course.name.toLowerCase().contains(query.toLowerCase()) ||
          (course.description?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (course.mosqueName?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  Future<List<HifzLog>> searchHifzLogs(String query) async {
    final logs = await getHifzLogs();
    return logs.where((log) {
      return log.studentName.toLowerCase().contains(query.toLowerCase()) ||
          log.courseName.toLowerCase().contains(query.toLowerCase()) ||
          log.sheikhName.toLowerCase().contains(query.toLowerCase()) ||
          (log.comments?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }
}

// Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
