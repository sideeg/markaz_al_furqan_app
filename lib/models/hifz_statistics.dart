// Path: lib/models/hifz_statistics.dart

class HifzStatistics {
  final int totalSessions;
  final int totalAyahs;
  final double averageEvaluation; // out of 5
  final double quranCompletionPercentage; // 0-100

  const HifzStatistics({
    this.totalSessions = 0,
    this.totalAyahs = 0,
    this.averageEvaluation = 0.0,
    this.quranCompletionPercentage = 0.0,
  });

  factory HifzStatistics.fromJson(Map<String, dynamic> json) {
    return HifzStatistics(
      totalSessions: (json['total_sessions'] as num? ?? 0).toInt(),
      totalAyahs: (json['total_ayahs_memorized'] as num? ?? 0).toInt(),

      // FIXED: Matching the new backend key 'average_evaluation_out_of_5'
      averageEvaluation:
          (json['average_evaluation_out_of_5'] as num? ?? 0.0).toDouble(),

      // FIXED: Ensure this remains a double
      quranCompletionPercentage:
          (json['quran_completion_percentage'] as num? ?? 0.0).toDouble(),
    );
  }

  // Get evaluation percentage (out of 5)
  int get evaluationPercentage => ((averageEvaluation / 5) * 100).round();

  HifzStatistics copyWith({
    int? totalSessions,
    int? totalAyahs,
    double? averageEvaluation,
    double? quranCompletionPercentage,
  }) {
    return HifzStatistics(
      totalSessions: totalSessions ?? this.totalSessions,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      averageEvaluation: averageEvaluation ?? this.averageEvaluation,
      quranCompletionPercentage:
          quranCompletionPercentage ?? this.quranCompletionPercentage,
    );
  }
}
