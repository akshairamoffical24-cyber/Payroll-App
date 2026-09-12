import 'api_config.dart';

class ApiEndpoints {
  static String get baseUrl => ApiConfig.baseUrl;

  // Health
  static String get health => '$baseUrl/health';

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get googleLogin => '$baseUrl/auth/google';
  static String get currentUser => '$baseUrl/auth/me';
  static String get sendOtp => '$baseUrl/auth/otp/send';
  static String get verifyOtp => '$baseUrl/auth/otp/verify';

  // Employees
  static String get employees => '$baseUrl/employees';
  static String employeeById(String id) => '$baseUrl/employees/$id';
  static String toggleEmployeeStatus(String id) => '$baseUrl/employees/$id/toggle-status';
  static String get importEmployees => '$baseUrl/employees/import';

  // Sites
  static String get sites => '$baseUrl/sites';
  static String siteById(String id) => '$baseUrl/sites/$id';
  static String toggleSiteStatus(String id) => '$baseUrl/sites/$id/toggle-status';

  // Mappings
  static String get mappings => '$baseUrl/mappings';
  static String mappingsByEmployee(String employeeId) => '$baseUrl/mappings/employee/$employeeId';
  static String activeSiteIdsForEmployee(String employeeId) => '$baseUrl/mappings/employee/$employeeId/active-sites';
  static String toggleMappingStatus(String id) => '$baseUrl/mappings/$id/toggle-status';

  // Attendance
  static String get mobilePunch => '$baseUrl/attendance/punches/mobile';
  static String get syncOfflinePunches => '$baseUrl/attendance/punches/sync';
  static String get allPunches => '$baseUrl/attendance/punches';
  static String get dailyAttendance => '$baseUrl/attendance/daily';
  static String dailyAttendanceForEmployee(String employeeId) => '$baseUrl/attendance/daily/employee/$employeeId';

  // Biometric
  static String get ingestBiometric => '$baseUrl/biometric/ingest';

  // Leaves
  static String get leaves => '$baseUrl/leaves';
  static String leavesForEmployee(String employeeId) => '$baseUrl/leaves/employee/$employeeId';

  // Regularization
  static String get regularization => '$baseUrl/regularization';
  static String regularizationForEmployee(String employeeId) => '$baseUrl/regularization/employee/$employeeId';
  static String reviewRegularization(String id) => '$baseUrl/regularization/$id/review';

  // Payroll
  static String get payroll => '$baseUrl/payroll';
  static String get calculatePayroll => '$baseUrl/payroll/calculate';
  static String updatePayrollStatus(String id) => '$baseUrl/payroll/$id/status';

  // Notifications
  static String get notifications => '$baseUrl/notifications';
  static String get markAllNotificationsRead => '$baseUrl/notifications/mark-all-read';

  // Audit Logs
  static String get auditLogs => '$baseUrl/audit-logs';

  // Face Biometrics
  static String get registerFace => '$baseUrl/face/register';
  static String faceStatus(String employeeId) => '$baseUrl/face/status/$employeeId';
  static String invalidateFace(String employeeId) => '$baseUrl/face/invalidate/$employeeId';

  // System Settings
  static String get settings => '$baseUrl/settings';
}
