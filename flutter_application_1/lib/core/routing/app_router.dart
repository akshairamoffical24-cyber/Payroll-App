import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/attendance/presentation/regularization_approvals_screen.dart';
import '../../features/audit_logs/presentation/audit_logs_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/biometric/presentation/biometric_screen.dart';
import '../../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/hr_dashboard_screen.dart';
import '../../features/employee_site_mapping/presentation/site_mapping_screen.dart';
import '../../features/employees/presentation/employee_onboarding_screen.dart';
import '../../features/employees/presentation/employees_screen.dart';
import '../../features/employees/presentation/import_history_screen.dart';
import '../../features/field_attendance/presentation/field_dashboard_screen.dart';
import '../../features/field_attendance/presentation/gps_verification_screen.dart';
import '../../features/field_attendance/presentation/punch_screen.dart';
import '../../features/main_shell.dart';
import '../../features/maps/presentation/interactive_map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/payroll/presentation/payroll_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sites/presentation/sites_screen.dart';
import '../../shared/models/site.dart';
import '../../shared/models/user.dart';
import '../providers/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return (user.role == UserRole.fieldStaff) ? '/field-dashboard' : '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Mobile Field Staff Routes
      GoRoute(
        path: '/field-dashboard',
        builder: (context, state) => const FieldDashboardScreen(),
      ),
      GoRoute(
        path: '/field-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return GpsVerificationScreen(
            isPunchOut: extra['isPunchOut'] as bool? ?? false,
            employeeId: extra['employeeId'] as String? ?? 'EMP-001',
          );
        },
      ),
      GoRoute(
        path: '/field-punch',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final site = extra['site'] as Site;
          return PunchScreen(
            site: site,
            isPunchOut: extra['isPunchOut'] as bool? ?? false,
            employeeId: extra['employeeId'] as String? ?? 'EMP-001',
            latitude: (extra['latitude'] as num?)?.toDouble() ?? site.latitude,
            longitude: (extra['longitude'] as num?)?.toDouble() ?? site.longitude,
            accuracy: (extra['accuracy'] as num?)?.toDouble() ?? 5.0,
            distanceMeters: (extra['distanceMeters'] as num?)?.toDouble() ?? 40.0,
          );
        },
      ),

      // Enterprise Admin & HR Shell Routes
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(
            currentPath: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              final user = ref.watch(authStateProvider);
              if (user?.role == UserRole.hr) {
                return const HrDashboardScreen();
              }
              return const AdminDashboardScreen();
            },
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeesScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const EmployeeOnboardingScreen(),
          ),
          GoRoute(
            path: '/employee-onboarding',
            builder: (context, state) => const EmployeeOnboardingScreen(),
          ),
          GoRoute(
            path: '/import-history',
            builder: (context, state) => const ImportHistoryScreen(),
          ),
          GoRoute(
            path: '/sites',
            builder: (context, state) => const SitesScreen(),
          ),
          GoRoute(
            path: '/site-mapping',
            builder: (context, state) => const SiteMappingScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/regularization-approvals',
            builder: (context, state) => const RegularizationApprovalsScreen(),
          ),
          GoRoute(
            path: '/biometric',
            builder: (context, state) => const BiometricScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const InteractiveMapScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/payroll',
            builder: (context, state) => const PayrollScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/audit-logs',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
