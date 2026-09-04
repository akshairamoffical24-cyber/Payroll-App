enum UserRole {
  admin,
  hr,
  fieldStaff;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.hr:
        return 'HR Manager';
      case UserRole.fieldStaff:
        return 'Field Staff';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isHr => this == UserRole.hr;
  bool get isFieldStaff => this == UserRole.fieldStaff;
}

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? employeeId;
  final String? department;
  final String? avatarUrl;
  final String? token;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.employeeId,
    this.department,
    this.avatarUrl,
    this.token,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? employeeId,
    String? department,
    String? avatarUrl,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'employeeId': employeeId,
      'department': department,
      'avatarUrl': avatarUrl,
      'token': token,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['role']?.toString().toLowerCase().replaceAll('_', '') ?? '';
    UserRole parsedRole = UserRole.fieldStaff;
    if (roleRaw == 'admin') {
      parsedRole = UserRole.admin;
    } else if (roleRaw == 'hr') {
      parsedRole = UserRole.hr;
    } else {
      parsedRole = UserRole.fieldStaff;
    }

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: parsedRole,
      employeeId: json['employeeId']?.toString(),
      department: json['department']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      token: json['token']?.toString(),
    );
  }
}
