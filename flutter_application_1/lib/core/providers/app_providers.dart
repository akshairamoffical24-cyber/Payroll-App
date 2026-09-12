import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/attendance/data/attendance_repository.dart';
import '../../features/attendance/data/http_leave_repository.dart';
import '../../features/attendance/data/http_regularization_repository.dart';
import '../../features/audit_logs/data/audit_repository.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/biometric/data/biometric_adapter.dart';
import '../../features/employee_site_mapping/data/mapping_repository.dart';
import '../../features/employees/data/employee_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/payroll/data/payroll_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/sites/data/site_repository.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/models/attendance_punch.dart';
import '../../shared/models/audit_log.dart';
import '../../shared/models/daily_attendance.dart';
import '../../shared/models/employee.dart';
import '../../shared/models/employee_site_mapping.dart';
import '../../shared/models/leave_request.dart';
import '../../shared/models/regularization_request.dart';
import '../../shared/models/site.dart';
import '../../features/attendance/data/http_attendance_repository.dart';
import '../../features/audit_logs/data/http_audit_repository.dart';
import '../../features/authentication/data/http_auth_repository.dart';
import '../../features/authentication/data/google_auth_service.dart';
import '../../features/employee_site_mapping/data/http_mapping_repository.dart';
import '../../features/employees/data/http_employee_repository.dart';
import '../../features/notifications/data/http_notification_repository.dart';
import '../../features/payroll/data/http_payroll_repository.dart';
import '../../features/sites/data/http_site_repository.dart';
import '../../shared/models/import_job.dart';
import '../../shared/models/user.dart';
import '../permissions/location_service.dart';
import '../services/analytics_engine.dart';
import '../services/excel_import_service.dart';

// --- Singleton Repository Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository();
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return HttpEmployeeRepository();
});

final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  return HttpSiteRepository();
});

final mappingRepositoryProvider = Provider<MappingRepository>((ref) {
  return HttpMappingRepository();
});

final biometricAdapterProvider = Provider<BiometricAttendanceSource>((ref) {
  return SimulatedBiometricAdapter();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return HttpAttendanceRepository();
});

final regularizationRepositoryProvider = Provider<RegularizationRepository>((ref) {
  return HttpRegularizationRepository();
});

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return HttpLeaveRepository();
});

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return HttpPayrollRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return HttpNotificationRepository();
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return HttpAuditRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return HttpSettingsRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return GeofenceService();
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final excelImportServiceProvider = Provider<ExcelImportService>((ref) {
  return ExcelImportService();
});

// Import Jobs History State
class ImportJobsNotifier extends StateNotifier<List<ImportJob>> {
  ImportJobsNotifier() : super([]);

  void addJob(ImportJob job) {
    state = [job, ...state];
  }
}

final importJobsProvider = StateNotifierProvider<ImportJobsNotifier, List<ImportJob>>((ref) {
  return ImportJobsNotifier();
});

// Dynamic Analytics Engine Provider (Zero fake numbers, computed dynamically from active backend datasets)
final analyticsSummaryProvider = Provider.autoDispose<AnalyticsSummary>((ref) {
  final employees = ref.watch(employeesListProvider).value ?? [];
  final sites = ref.watch(sitesListProvider).value ?? [];
  final mappings = ref.watch(mappingsListProvider).value ?? [];
  final attendance = ref.watch(dailyAttendanceListProvider).value ?? [];
  final punches = ref.watch(allPunchesProvider).value ?? [];

  return AnalyticsEngine.computeSummary(
    employees: employees,
    sites: sites,
    mappings: mappings,
    attendanceRecords: attendance,
    rawPunches: punches,
  );
});

// --- State Controllers & Notifiers ---

// Current Authenticated User State
class AuthStateNotifier extends StateNotifier<User?> {
  final AuthRepository _authRepo;
  final GoogleAuthService _googleAuthService;

  AuthStateNotifier(this._authRepo, this._googleAuthService) : super(null) {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final user = await _authRepo.getCurrentUser();
    if (user != null) {
      state = user;
    }
  }

  Future<void> login({required String emailOrId, required String password}) async {
    final user = await _authRepo.login(
      emailOrId: emailOrId,
      password: password,
    );
    state = user;
  }

  Future<void> signInWithGoogle({GoogleAuthPayload? payload}) async {
    final user = await _authRepo.signInWithGoogle(payload: payload);
    state = user;
  }

  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    return await _authRepo.sendOtp(mobile);
  }

  Future<void> loginWithOtp({required String mobile, required String otp}) async {
    final user = await _authRepo.loginWithOtp(mobile: mobile, otp: otp);
    state = user;
  }

  void updateUserName(String newName) {
    if (state != null) {
      final updated = state!.copyWith(name: newName.trim());
      state = updated;
      _authRepo.updateLocalUser(updated);
    }
  }

  Future<void> logout() async {
    try {
      await _googleAuthService.signOut();
    } catch (_) {}
    await _authRepo.logout();
    state = null;
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final googleAuth = ref.watch(googleAuthServiceProvider);
  return AuthStateNotifier(authRepo, googleAuth);
});

// Employees List State
final employeesListProvider = FutureProvider.autoDispose<List<Employee>>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.getAllEmployees();
});

// Sites List State
final sitesListProvider = FutureProvider.autoDispose<List<Site>>((ref) async {
  final repo = ref.watch(siteRepositoryProvider);
  return repo.getAllSites();
});

// Mappings List State
final mappingsListProvider = FutureProvider.autoDispose<List<EmployeeSiteMapping>>((ref) async {
  final repo = ref.watch(mappingRepositoryProvider);
  return repo.getAllMappings();
});

// Daily Attendance List State
final dailyAttendanceListProvider = FutureProvider.autoDispose<List<DailyAttendance>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getDailyAttendanceList();
});

// All Punches State
final allPunchesProvider = FutureProvider.autoDispose<List<AttendancePunch>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAllPunches();
});

// Notifications List State
final notificationsListProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications();
});

// Audit Logs State
final auditLogsListProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getAuditLogs();
});

// System Settings State
final systemSettingsProvider = FutureProvider.autoDispose<SystemSettings>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSettings();
});

// Selected Date Filter for Attendance & Reports
final selectedAttendanceDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// --- Late Punch & Regularization Approval Requests State ---
class RegularizationRequestsNotifier extends StateNotifier<List<RegularizationRequest>> {
  final RegularizationRepository _repo;

  RegularizationRequestsNotifier(this._repo) : super([]) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      final list = await _repo.getAllRequests();
      state = list;
    } catch (_) {}
  }

  Future<void> addRequest(RegularizationRequest request) async {
    try {
      final created = await _repo.submitRequest(
        employeeId: request.employeeId,
        requestType: request.requestType,
        reasonCategory: request.reasonCategory,
        attendanceDate: request.attendanceDate,
        requestedInTime: request.requestedInTime,
        requestedOutTime: request.requestedOutTime,
        remarks: request.remarks,
      );
      state = [created, ...state];
    } catch (_) {
      state = [request, ...state];
    }
  }

  Future<void> approveRequest({required String requestId, required String reviewerName, String? remarks}) async {
    try {
      final updated = await _repo.reviewRequest(
        id: requestId,
        status: 'approved',
        reviewerName: reviewerName,
        reviewerRole: reviewerName.contains('Admin') ? 'Admin' : 'HR',
        remarks: remarks,
      );
      state = state.map((r) => r.id == requestId ? updated : r).toList();
    } catch (_) {
      state = state.map((req) {
        if (req.id == requestId) {
          return req.copyWith(
            status: RegularizationStatus.approved,
            reviewedBy: reviewerName,
            reviewedAt: DateTime.now(),
            adminReviewRemarks: remarks ?? 'Approved by $reviewerName',
          );
        }
        return req;
      }).toList();
    }
  }

  Future<void> rejectRequest({required String requestId, required String reviewerName, required String reason}) async {
    try {
      final updated = await _repo.reviewRequest(
        id: requestId,
        status: 'rejected',
        reviewerName: reviewerName,
        reviewerRole: reviewerName.contains('Admin') ? 'Admin' : 'HR',
        remarks: reason,
      );
      state = state.map((r) => r.id == requestId ? updated : r).toList();
    } catch (_) {
      state = state.map((req) {
        if (req.id == requestId) {
          return req.copyWith(
            status: RegularizationStatus.rejected,
            reviewedBy: reviewerName,
            reviewedAt: DateTime.now(),
            adminReviewRemarks: reason,
          );
        }
        return req;
      }).toList();
    }
  }
}

final regularizationRequestsProvider =
    StateNotifierProvider<RegularizationRequestsNotifier, List<RegularizationRequest>>((ref) {
  final repo = ref.watch(regularizationRepositoryProvider);
  return RegularizationRequestsNotifier(repo);
});

// Employee-Specific Leaves & Regularizations Family Providers
final employeeLeavesProvider =
    FutureProvider.family.autoDispose<List<LeaveRequest>, String>((ref, employeeId) async {
  if (employeeId.isEmpty) return [];
  final repo = ref.watch(leaveRepositoryProvider);
  return repo.getLeavesForEmployee(employeeId);
});

final employeeRegularizationsProvider =
    FutureProvider.family.autoDispose<List<RegularizationRequest>, String>((ref, employeeId) async {
  if (employeeId.isEmpty) return [];
  final repo = ref.watch(regularizationRepositoryProvider);
  return repo.getRequestsForEmployee(employeeId);
});

class LeaveRequestsNotifier extends StateNotifier<List<LeaveRequest>> {
  final LeaveRepository _repo;

  LeaveRequestsNotifier(this._repo) : super([]) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      final list = await _repo.getAllLeaves();
      state = list;
    } catch (_) {}
  }

  Future<LeaveRequest> addLeave({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final created = await _repo.submitLeaveRequest(
      employeeId: employeeId,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );
    state = [created, ...state];
    return created;
  }
}

final leaveRequestsProvider =
    StateNotifierProvider<LeaveRequestsNotifier, List<LeaveRequest>>((ref) {
  final repo = ref.watch(leaveRepositoryProvider);
  return LeaveRequestsNotifier(repo);
});
