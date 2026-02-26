import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String role; // admin, hr, staff

  @HiveField(4)
  final String? phone;

  @HiveField(5)
  final String? department;

  @HiveField(6)
  final String? designation;

  @HiveField(7)
  final String? profileImage;

  @HiveField(8)
  final DateTime? joinedDate;

  @HiveField(9)
  final double casualLeaveBalance;

  @HiveField(10)
  final double shortLeaveBalance;

  @HiveField(11)
  final bool isActive;

  @HiveField(12)
  final DateTime? createdAt;

  @HiveField(13)
  final DateTime? updatedAt;

  @HiveField(14)
  final double halfDayLeaveBalance; // Keeping for backward compatibility if needed

  @HiveField(15)
  final double annualLeaveBalance;

  @HiveField(16)
  final double medicalLeaveBalance;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.department,
    this.designation,
    this.profileImage,
    this.joinedDate,
    this.casualLeaveBalance = 0.0,
    this.shortLeaveBalance = 0.0,
    this.halfDayLeaveBalance = 0.0,
    this.annualLeaveBalance = 0.0,
    this.medicalLeaveBalance = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'staff',
      phone: json['phone'],
      department: json['department'],
      designation: json['designation'],
      profileImage: json['profile_image'],
      joinedDate: json['joined_date'] != null
          ? DateTime.parse(json['joined_date'])
          : null,
      casualLeaveBalance: _parseToDouble(json['casual_leave_balance']),
      shortLeaveBalance: _parseToDouble(json['short_leave_balance']),
      halfDayLeaveBalance: _parseToDouble(json['half_day_leave_balance']),
      annualLeaveBalance: _parseToDouble(json['annual_leave_balance']),
      medicalLeaveBalance: _parseToDouble(json['medical_leave_balance']),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'department': department,
      'designation': designation,
      'profile_image': profileImage,
      'joined_date': joinedDate?.toIso8601String(),
      'casual_leave_balance': casualLeaveBalance,
      'short_leave_balance': shortLeaveBalance,
      'half_day_leave_balance': halfDayLeaveBalance,
      'annual_leave_balance': annualLeaveBalance,
      'medical_leave_balance': medicalLeaveBalance,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? department,
    String? designation,
    String? profileImage,
    DateTime? joinedDate,
    double? casualLeaveBalance,
    double? shortLeaveBalance,
    double? halfDayLeaveBalance,
    double? annualLeaveBalance,
    double? medicalLeaveBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      profileImage: profileImage ?? this.profileImage,
      joinedDate: joinedDate ?? this.joinedDate,
      casualLeaveBalance: casualLeaveBalance ?? this.casualLeaveBalance,
      shortLeaveBalance: shortLeaveBalance ?? this.shortLeaveBalance,
      halfDayLeaveBalance: halfDayLeaveBalance ?? this.halfDayLeaveBalance,
      annualLeaveBalance: annualLeaveBalance ?? this.annualLeaveBalance,
      medicalLeaveBalance: medicalLeaveBalance ?? this.medicalLeaveBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isHR => role == 'hr';
  bool get isStaff => role == 'staff';
  bool get isProjectManager => role == 'project_manager';
}
