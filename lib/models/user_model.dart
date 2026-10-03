// USER role model — Nurse and Staff are both treated as USER in the Flutter app.
// Passwords are NEVER stored here. Authentication is handled by Flask → Supabase Auth.
// Fields mapped directly from the backend profiles table response.

enum UserRole { user, admin }

class UserModel {
  final String id;          // UUID from profiles.id / auth.users.id
  final String name;        // profiles.name
  final String email;       // profiles.email
  final String department;  // profiles.department
  final String shift;       // profiles.shift
  final String employeeId;  // profiles.employee_id (may be empty)
  final String avatarUrl;   // profiles.avatar_url
  final UserRole role;      // Derived: ADMIN → admin, NURSE/STAFF → user
  final bool isActive;      // profiles.is_active

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.shift,
    required this.employeeId,
    required this.avatarUrl,
    required this.role,
    required this.isActive,
  });

  /// Factory constructor: creates a UserModel from the backend profile JSON.
  /// Backend profile fields: id, name, email, role, department, shift,
  ///   employee_id, avatar_url, is_active, created_at, updated_at
  factory UserModel.fromProfileJson(Map<String, dynamic> profile, {String? defaultEmail}) {
    final rawRole = (profile['role'] ?? '').toString().toUpperCase();
    final userRole = rawRole == 'ADMIN' ? UserRole.admin : UserRole.user;

    return UserModel(
      id: profile['id']?.toString() ?? '',
      name: profile['name']?.toString() ?? 'User',
      email: profile['email']?.toString() ?? defaultEmail ?? '',
      department: profile['department']?.toString() ?? 'General Ward',
      shift: profile['shift']?.toString() ?? 'Morning (07:00 - 15:00)',
      employeeId: profile['employee_id']?.toString() ?? '',
      avatarUrl: profile['avatar_url']?.toString() ?? '',
      role: userRole,
      isActive: profile['is_active'] != false,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? shift,
    String? employeeId,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      shift: shift ?? this.shift,
      employeeId: employeeId ?? this.employeeId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
