import 'dart:async';
import '../../../shared/models/user.dart';
import '../../employees/data/employee_repository.dart';
import 'google_auth_service.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login({required String emailOrId, required String password});
  Future<User> signInWithGoogle({GoogleAuthPayload? payload});
  Future<Map<String, dynamic>> sendOtp(String mobile);
  Future<User> loginWithOtp({required String mobile, required String otp});
  Future<void> logout();
  void updateLocalUser(User user);
}

class MockAuthRepository implements AuthRepository {
  User? _currentUser;

  static final List<User> demoUsers = [
    const User(
      id: 'USR-ADM-001',
      email: 'admin@workpulse.com',
      name: 'Premkumar',
      role: UserRole.admin,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      token: 'jwt_admin_token_xyz890',
    ),
    const User(
      id: 'USR-HR-001',
      email: 'hr@workpulse.com',
      name: 'Sarah Jenkins',
      role: UserRole.hr,
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      token: 'jwt_hr_token_abc123',
    ),
  ];

  @override
  void updateLocalUser(User user) {
    _currentUser = user;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<User> signInWithGoogle({GoogleAuthPayload? payload}) async {
    await Future.delayed(const Duration(milliseconds: 650));
    final email = payload?.email.toLowerCase().trim() ?? 'admin@workpulse.com';
    final name = payload?.name ?? (payload != null ? payload.email.split('@').first : 'Premkumar');

    if (email == 'admin@workpulse.com' || email.contains('admin')) {
      final user = User(
        id: 'USR-GGL-ADM',
        email: email,
        name: '$name (Google)',
        role: UserRole.admin,
        avatarUrl: payload?.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        token: 'jwt_google_admin_token',
      );
      _currentUser = user;
      return user;
    } else if (email == 'hr@workpulse.com' || email.contains('hr')) {
      final user = User(
        id: 'USR-GGL-HR',
        email: email,
        name: '$name (Google)',
        role: UserRole.hr,
        avatarUrl: payload?.avatarUrl ?? 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        token: 'jwt_google_hr_token',
      );
      _currentUser = user;
      return user;
    } else {
      // Check if email matches any registered employee
      final matchedEmp = MockEmployeeRepository.seedEmployees.where((e) {
        return e.email.toLowerCase().trim() == email;
      }).firstOrNull;

      if (matchedEmp != null) {
        final user = User(
          id: 'USR-${matchedEmp.id}',
          email: email,
          name: '$name (Google)',
          role: UserRole.fieldStaff,
          employeeId: matchedEmp.id,
          avatarUrl: payload?.avatarUrl ?? matchedEmp.avatarUrl,
          token: 'jwt_${matchedEmp.id}_token',
        );
        _currentUser = user;
        return user;
      }

      // If domain matches workpulse or contains employee hints
      if (email.endsWith('@workpulse.io') || email.endsWith('@workpulse.com') || email.contains('emp')) {
        final user = User(
          id: 'USR-GGL-EMP',
          email: email,
          name: '$name (Google)',
          role: UserRole.fieldStaff,
          employeeId: 'EMP-048', // Default active field staff employee
          avatarUrl: payload?.avatarUrl,
          token: 'jwt_google_field_token',
        );
        _currentUser = user;
        return user;
      }
    }

    throw Exception('Your Google account ($email) is not authorized to access this system. Please contact the administrator.');
  }

  @override
  Future<User> login({
    required String emailOrId,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final trimmed = emailOrId.trim().toLowerCase();

    // 1. Admin login match
    if (trimmed.contains('admin') || trimmed == 'admin@workpulse.com') {
      final user = demoUsers.firstWhere((u) => u.role == UserRole.admin);
      _currentUser = user;
      return user;
    }

    // 2. HR login match
    if (trimmed.contains('hr') || trimmed == 'hr@workpulse.com') {
      final user = demoUsers.firstWhere((u) => u.role == UserRole.hr);
      _currentUser = user;
      return user;
    }

    // 3. Employee match against existing employee database
    final matchedEmp = MockEmployeeRepository.seedEmployees.where((e) {
      final codeNorm = e.code.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      final idNorm = e.id.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      final inputNorm = trimmed.replaceAll('-', '').replaceAll(' ', '');
      return e.email.toLowerCase() == trimmed ||
          codeNorm == inputNorm ||
          idNorm == inputNorm ||
          e.name.toLowerCase().contains(trimmed) ||
          (trimmed.contains('emp') && (codeNorm.contains(inputNorm) || idNorm.contains(inputNorm)));
    }).firstOrNull;

    if (matchedEmp != null) {
      final user = User(
        id: 'USR-${matchedEmp.id}',
        email: matchedEmp.email,
        name: matchedEmp.name,
        role: UserRole.fieldStaff,
        employeeId: matchedEmp.id,
        avatarUrl: matchedEmp.avatarUrl,
        token: 'jwt_${matchedEmp.id}_token',
      );
      _currentUser = user;
      return user;
    }

    // 4. Flexible Dynamic Employee Fallback (e.g. EMP-101, EMP101, or custom staff IDs)
    if (trimmed.startsWith('emp') || trimmed.contains('staff') || trimmed.contains('@')) {
      final formattedEmpId = trimmed.toUpperCase().startsWith('EMP')
          ? (trimmed.contains('-') ? trimmed.toUpperCase() : 'EMP-${trimmed.substring(3)}')
          : 'EMP-101';
      final user = User(
        id: 'USR-$formattedEmpId',
        email: trimmed.contains('@') ? trimmed : '${trimmed.toLowerCase()}@workpulse.io',
        name: 'Staff $formattedEmpId',
        role: UserRole.fieldStaff,
        employeeId: formattedEmpId,
        token: 'jwt_${formattedEmpId}_token',
      );
      _currentUser = user;
      return user;
    }

    throw Exception('Invalid credentials. Please check your Email / Employee ID and password.');
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final suffix = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    final matchedEmp = MockEmployeeRepository.seedEmployees.where((e) {
      final empPhone = e.phone.replaceAll(RegExp(r'\D'), '');
      return empPhone.endsWith(suffix);
    }).firstOrNull;

    final empName = matchedEmp?.name ?? 'Employee';
    return {
      'success': true,
      'mobile': mobile,
      'otp': '123456',
      'message': 'OTP sent successfully to registered mobile number for $empName',
      'employeeName': empName,
    };
  }

  @override
  Future<User> loginWithOtp({required String mobile, required String otp}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (otp != '123456') {
      throw Exception('Invalid OTP. Please enter 123456 in demo mode.');
    }
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    final suffix = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    final matchedEmp = MockEmployeeRepository.seedEmployees.where((e) {
      final empPhone = e.phone.replaceAll(RegExp(r'\D'), '');
      return empPhone.endsWith(suffix);
    }).firstOrNull;

    final empId = matchedEmp?.id ?? 'EMP-001';
    final empName = matchedEmp?.name ?? 'Field Staff';
    final user = User(
      id: 'USR-$empId',
      email: matchedEmp?.email ?? '$suffix@workpulse.io',
      name: empName,
      role: UserRole.fieldStaff,
      employeeId: empId,
      avatarUrl: matchedEmp?.avatarUrl,
      token: 'jwt_${empId}_otp_token',
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
