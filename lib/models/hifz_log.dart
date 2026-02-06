import 'package:hive/hive.dart';

part 'hifz_log.g.dart';

@HiveType(typeId: 2)
class HifzLog extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final int studentId;
  
  @HiveField(2)
  final String studentName;
  
  @HiveField(3)
  final int courseId;
  
  @HiveField(4)
  final String courseName;
  
  @HiveField(5)
  final int sheikhId;
  
  @HiveField(6)
  final String sheikhName;
  
  @HiveField(7)
  final DateTime sessionDate;
  
  @HiveField(8)
  final int startSura;
  
  @HiveField(9)
  final int startAyah;
  
  @HiveField(10)
  final int endSura;
  
  @HiveField(11)
  final int endAyah;
  
  @HiveField(12)
  final String evaluation; // excellent, very_good, good, needs_improvement, poor
  
  @HiveField(13)
  final int? fluencyScore; // 1-10
  
  @HiveField(14)
  final int? tajweedScore; // 1-10
  
  @HiveField(15)
  final int? memorizationScore; // 1-10
  
  @HiveField(16)
  final String? comments;
  
  @HiveField(17)
  final String? nextAssignment;
  
  @HiveField(18)
  final DateTime createdAt;
  
  @HiveField(19)
  final DateTime updatedAt;

  HifzLog({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.sheikhId,
    required this.sheikhName,
    required this.sessionDate,
    required this.startSura,
    required this.startAyah,
    required this.endSura,
    required this.endAyah,
    required this.evaluation,
    this.fluencyScore,
    this.tajweedScore,
    this.memorizationScore,
    this.comments,
    this.nextAssignment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HifzLog.fromJson(Map<String, dynamic> json) {
    return HifzLog(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String,
      courseId: json['course_id'] as int,
      courseName: json['course_name'] as String,
      sheikhId: json['sheikh_id'] as int,
      sheikhName: json['sheikh_name'] as String,
      sessionDate: DateTime.parse(json['session_date'] as String),
      startSura: json['start_sura'] as int,
      startAyah: json['start_ayah'] as int,
      endSura: json['end_sura'] as int,
      endAyah: json['end_ayah'] as int,
      evaluation: json['evaluation'] as String,
      fluencyScore: json['fluency_score'] as int?,
      tajweedScore: json['tajweed_score'] as int?,
      memorizationScore: json['memorization_score'] as int?,
      comments: json['comments'] as String?,
      nextAssignment: json['next_assignment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'course_id': courseId,
      'course_name': courseName,
      'sheikh_id': sheikhId,
      'sheikh_name': sheikhName,
      'session_date': sessionDate.toIso8601String().split('T')[0],
      'start_sura': startSura,
      'start_ayah': startAyah,
      'end_sura': endSura,
      'end_ayah': endAyah,
      'evaluation': evaluation,
      'fluency_score': fluencyScore,
      'tajweed_score': tajweedScore,
      'memorization_score': memorizationScore,
      'comments': comments,
      'next_assignment': nextAssignment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HifzLog copyWith({
    int? id,
    int? studentId,
    String? studentName,
    int? courseId,
    String? courseName,
    int? sheikhId,
    String? sheikhName,
    DateTime? sessionDate,
    int? startSura,
    int? startAyah,
    int? endSura,
    int? endAyah,
    String? evaluation,
    int? fluencyScore,
    int? tajweedScore,
    int? memorizationScore,
    String? comments,
    String? nextAssignment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HifzLog(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      sheikhId: sheikhId ?? this.sheikhId,
      sheikhName: sheikhName ?? this.sheikhName,
      sessionDate: sessionDate ?? this.sessionDate,
      startSura: startSura ?? this.startSura,
      startAyah: startAyah ?? this.startAyah,
      endSura: endSura ?? this.endSura,
      endAyah: endAyah ?? this.endAyah,
      evaluation: evaluation ?? this.evaluation,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      tajweedScore: tajweedScore ?? this.tajweedScore,
      memorizationScore: memorizationScore ?? this.memorizationScore,
      comments: comments ?? this.comments,
      nextAssignment: nextAssignment ?? this.nextAssignment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HifzLog(id: $id, student: $studentName, evaluation: $evaluation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HifzLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
  
  // Helper getters
  String get evaluationDisplayName {
    switch (evaluation) {
      case 'excellent':
        return 'ممتاز';
      case 'very_good':
        return 'جيد جداً';
      case 'good':
        return 'جيد';
      case 'needs_improvement':
        return 'يحتاج تحسين';
      case 'poor':
        return 'ضعيف';
      default:
        return evaluation;
    }
  }
  
  double get averageScore {
    final scores = [fluencyScore, tajweedScore, memorizationScore]
        .where((score) => score != null)
        .cast<int>();
    
    if (scores.isEmpty) return 0.0;
    
    return scores.reduce((a, b) => a + b) / scores.length;
  }
  
  String get suraRange {
    if (startSura == endSura) {
      return getSuraName(startSura);
    }
    return '${getSuraName(startSura)} - ${getSuraName(endSura)}';
  }
  
  String get ayahRange {
    if (startSura == endSura) {
      if (startAyah == endAyah) {
        return 'الآية $startAyah';
      }
      return 'الآيات $startAyah-$endAyah';
    }
    return 'من ${getSuraName(startSura)} آية $startAyah إلى ${getSuraName(endSura)} آية $endAyah';
  }
  
  String getSuraName(int suraNumber) {
    // This would typically come from a constants file with all sura names
    final suraNames = {
      1: 'الفاتحة',
      2: 'البقرة',
      3: 'آل عمران',
      4: 'النساء',
      5: 'المائدة',
      // Add all 114 sura names here
    };
    
    return suraNames[suraNumber] ?? 'سورة $suraNumber';
  }
  
  bool get hasScores => fluencyScore != null || tajweedScore != null || memorizationScore != null;
  
  String get formattedDate {
    return '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
  }
}

