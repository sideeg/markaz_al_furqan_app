class HifzStatistics {
  final double averagePages;
  final int maxPages;
  final int minPages;
  final int totalSessions;
  final int totalAyahs;
  final double averageEvaluation;

  HifzStatistics({
    required this.averagePages,
    required this.maxPages,
    required this.minPages,
    required this.totalSessions,
    this.totalAyahs = 0,
    this.averageEvaluation = 0.0,
  });

  factory HifzStatistics.fromJson(Map<String, dynamic> json) {
    return HifzStatistics(
      averagePages: (json['avg'] ?? 0).toDouble(),
      maxPages: json['max'] ?? 0,
      minPages: json['min'] ?? 0,
      totalSessions: json['count'] ?? 0,
    );
  }

  // Get evaluation percentage (out of 5)
  int get evaluationPercentage => ((averageEvaluation / 5) * 100).round();
}

class CourseProgress {
  final int courseId;
  final int totalPages;

  CourseProgress({
    required this.courseId,
    required this.totalPages,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['course_id'],
      totalPages: json['pages'] ?? 0,
    );
  }
}
