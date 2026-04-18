import 'package:hive/hive.dart';

part 'mosque.g.dart';

@HiveType(typeId: 3)
class Mosque extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? address;

  @HiveField(4)
  final String? city;

  @HiveField(5)
  final String? phone;

  @HiveField(6)
  final String? email;

  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  @HiveField(9)
  final String? imagePath;

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final int? createdBy;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  Mosque({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.imagePath,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      imagePath: json['image_path'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'image_path': imagePath,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Mosque copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    String? imagePath,
    bool? isActive,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mosque(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get fullAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    return parts.join(' - ');
  }

  bool get hasLocation => latitude != null && longitude != null;

  bool get hasContactInfo => phone != null || email != null;

  @override
  String toString() {
    return 'Mosque(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mosque && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
