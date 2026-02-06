import 'package:hive/hive.dart';

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
  final String type; // online, open, closed

  @HiveField(4)
  final int? mosqueId;

  @HiveField(5)
  final String? mosqueName;

  @HiveField(6)
  final String? imagePath;

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
  final String? enrollmentStatus; // For student's enrollment status

  Course({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.mosqueId,
    this.mosqueName,
    this.imagePath,
    this.startDate,
    this.endDate,
    this.maxStudents = 50,
    this.currentStudents = 0,
    this.isActive = true,
    this.isRegistrationOpen = true,
    this.requirements,
    this.scheduleDetails,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.enrollmentStatus,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      mosqueId: json['mosque_id'] as int?,
      mosqueName: json['mosque_name'] as String?,
      imagePath: json['image_path'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      maxStudents: json['max_students'] as int? ?? 50,
      currentStudents: json['current_students'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isRegistrationOpen: json['is_registration_open'] as bool? ?? true,
      requirements: json['requirements'] as String?,
      scheduleDetails: json['schedule_details'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      enrollmentStatus: json['enrollment_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'mosque_id': mosqueId,
      'mosque_name': mosqueName,
      'image_path': imagePath,
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
    };
  }

  Course copyWith({
    int? id,
    String? name,
    String? description,
    String? type,
    int? mosqueId,
    String? mosqueName,
    String? imagePath,
    DateTime? startDate,
    DateTime? endDate,
    int? maxStudents,
    int? currentStudents,
    bool? isActive,
    bool? isRegistrationOpen,
    String? requirements,
    String? scheduleDetails,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? enrollmentStatus,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      mosqueId: mosqueId ?? this.mosqueId,
      mosqueName: mosqueName ?? this.mosqueName,
      imagePath: imagePath ?? this.imagePath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      isActive: isActive ?? this.isActive,
      isRegistrationOpen: isRegistrationOpen ?? this.isRegistrationOpen,
      requirements: requirements ?? this.requirements,
      scheduleDetails: scheduleDetails ?? this.scheduleDetails,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
    );
  }

  @override
  String toString() {
    return 'Course(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper getters
  bool get isOnline => type == 'online';
  bool get isOpen => type == 'open';
  bool get isClosed => type == 'closed';

  bool get canEnroll =>
      isActive && isRegistrationOpen && currentStudents < maxStudents;

  bool get isEnrolled => enrollmentStatus != null;
  bool get isPending => enrollmentStatus == 'pending';
  bool get isApproved => enrollmentStatus == 'approved';
  bool get isRejected => enrollmentStatus == 'rejected';
  bool get isCompleted => enrollmentStatus == 'completed';
  bool get isDropped => enrollmentStatus == 'dropped';

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
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      case 'dropped':
        return 'منسحب';
      default:
        return 'غير مسجل';
    }
  }

  double get enrollmentPercentage {
    if (maxStudents == 0) return 0.0;
    return (currentStudents / maxStudents).clamp(0.0, 1.0);
  }

  int get availableSlots =>
      (maxStudents - currentStudents).clamp(0, maxStudents);
}
