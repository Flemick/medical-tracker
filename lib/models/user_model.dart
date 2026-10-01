enum UserRole { nurse, admin }

class UserModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String department;
  final String roleTitle;
  final String shift; // 'Morning (07:00 - 15:00)', 'Evening (15:00 - 23:00)', 'Night (23:00 - 07:00)'
  final UserRole role;
  final String pin; // default login pin
  final bool isActive;
  final DateTime createdAt;
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.department,
    required this.roleTitle,
    required this.shift,
    this.role = UserRole.nurse,
    required this.pin,
    this.isActive = true,
    required this.createdAt,
    this.avatarUrl = '',
  });

  UserModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? department,
    String? roleTitle,
    String? shift,
    UserRole? role,
    String? pin,
    bool? isActive,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      roleTitle: roleTitle ?? this.roleTitle,
      shift: shift ?? this.shift,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
