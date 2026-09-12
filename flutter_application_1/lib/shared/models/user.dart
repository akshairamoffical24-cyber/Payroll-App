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
  final String? employeeCode;
  final String? department;
  final String? designation;
  final String? phone;
  final double? monthlyCtc;
  final String? username;
  final String? avatarUrl;
  final String? token;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.employeeId,
    this.employeeCode,
    this.department,
    this.designation,
    this.phone,
    this.monthlyCtc,
    this.username,
    this.avatarUrl,
    this.token,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? employeeId,
    String? employeeCode,
    String? department,
    String? designation,
    String? phone,
    double? monthlyCtc,
    String? username,
    String? avatarUrl,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
      monthlyCtc: monthlyCtc ?? this.monthlyCtc,
      username: username ?? this.username,
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
      'employeeCode': employeeCode,
      'department': department,
      'designation': designation,
      'phone': phone,
      'monthlyCtc': monthlyCtc,
      'username': username,
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

    double? parsedMonthlyCtc;
    if (json['monthlyCtc'] != null) {
      if (json['monthlyCtc'] is num) {
        parsedMonthlyCtc = (json['monthlyCtc'] as num).toDouble();
      } else {
        parsedMonthlyCtc = double.tryParse(json['monthlyCtc'].toString());
      }
    }

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: parsedRole,
      employeeId: json['employeeId']?.toString(),
      employeeCode: json['employeeCode']?.toString(),
      department: json['department']?.toString(),
      designation: json['designation']?.toString(),
      phone: json['phone']?.toString(),
      monthlyCtc: parsedMonthlyCtc,
      username: json['username']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      token: json['token']?.toString(),
    );
  }
}
