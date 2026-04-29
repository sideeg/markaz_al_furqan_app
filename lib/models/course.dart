import 'package:hive/hive.dart';
import 'mosque.dart';
part 'course.g.dart';

@HiveType(typeId: 1)
class Course extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final int? mosqueId;

  @HiveField(5)
  final String? mosqueName;

  @HiveField(6)
  final String? image_url;

  @HiveField(7)
  final DateTime? startDate;

  @HiveField(8)
  final DateTime? endDate;

  @HiveField(9)
  final int maxStudents;

  @HiveField(10)
  final int currentStudents;

  @HiveField(11)
  final bool isActive;

  @HiveField(12)
  final bool isRegistrationOpen;

  @HiveField(13)
  final String? requirements;

  @HiveField(14)
  final String? scheduleDetails;

  @HiveField(15)
  final int? createdBy;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final String? enrollmentStatus;

  @HiveField(19)
  final Mosque? mosque;

  @HiveField(20)
  final bool isCompleted;

  @HiveField(21)
  final DateTime? completedAt;

  Course({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.mosqueId,
    this.mosqueName,
    this.image_url,
    this.startDate,
    this.endDate,
    required this.maxStudents,
    required this.currentStudents,
    required this.isActive,
    required this.isRegistrationOpen,
    this.requirements,
    this.scheduleDetails,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.enrollmentStatus,
    this.mosque,
    this.isCompleted = false,
    this.completedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      mosqueId: json['mosque_id'] as int?,
      mosqueName: json['mosque'] != null
          ? (json['mosque'] as Map<String, dynamic>)['name'] as String?
          : null,

      // ✅ THE FIX: use 'image_url' (appended accessor), NOT 'image_path'
      image_url: json['image_url'] as String?,

      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      maxStudents: json['max_students'] as int? ?? 0,
      currentStudents: json['current_students'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      isRegistrationOpen: json['is_registration_open'] as bool? ?? false,
      requirements: json['requirements'] as String?,
      scheduleDetails: json['schedule_details'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      enrollmentStatus: json['enrollment_status'] as String?,
      mosque: json['mosque'] != null
          ? Mosque.fromJson(json['mosque'] as Map<String, dynamic>)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'mosque_id': mosqueId,
      'image_url': image_url,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'max_students': maxStudents,
      'current_students': currentStudents,
      'is_active': isActive,
      'is_registration_open': isRegistrationOpen,
      'requirements': requirements,
      'schedule_details': scheduleDetails,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'enrollment_status': enrollmentStatus,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  double get enrollmentPercentage =>
      maxStudents > 0 ? (currentStudents / maxStudents).clamp(0.0, 1.0) : 0.0;

  int get availableSlots =>
      (maxStudents - currentStudents).clamp(0, maxStudents);

  bool get isFull => currentStudents >= maxStudents;

  bool get isEnrolled => enrollmentStatus != null && enrollmentStatus != 'none';

  bool get isPending => enrollmentStatus == 'pending';

  bool get isApproved => enrollmentStatus == 'approved';

  bool get canEnroll =>
      isActive && isRegistrationOpen && !isFull && !isCompleted && !isEnrolled;

  String get typeDisplayName {
    switch (type) {
      case 'online':
        return 'عبر الإنترنت';
      case 'open':
        return 'مفتوحة';
      case 'closed':
        return 'مغلقة';
      default:
        return type;
    }
  }

  String get enrollmentStatusDisplayName {
    switch (enrollmentStatus) {
      case 'approved':
        return 'تم قبول تسجيلك في الدورة';
      case 'pending':
        return 'طلبك قيد المراجعة';
      case 'rejected':
        return 'تم رفض طلب التسجيل';
      case 'completed':
        return 'أتممت هذه الدورة';
      default:
        return '';
    }
  }

  String get completedAtFormatted {
    if (completedAt == null) return '';
    return '${completedAt!.day}/${completedAt!.month}/${completedAt!.year}';
  }

  bool get getUserEnrollmentStatus => isEnrolled;
}
