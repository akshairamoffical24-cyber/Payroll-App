import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/attendance_punch.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/employee_site_mapping.dart';
import '../../../shared/models/leave_request.dart';
import '../../../shared/models/regularization_request.dart';
import '../../../shared/models/site.dart';
import '../../../shared/models/user.dart';
import '../../face_registration/presentation/face_registration_screen.dart';
import '../../notifications/presentation/notification_drawer.dart';

class FieldDashboardScreen extends ConsumerStatefulWidget {
  const FieldDashboardScreen({super.key});

  @override
  ConsumerState<FieldDashboardScreen> createState() => _FieldDashboardScreenState();
}

class _FieldDashboardScreenState extends ConsumerState<FieldDashboardScreen> {
  int _currentTab = 0; // 0: Home, 1: Attendance, 2: Requests, 3: Profile
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  late DateTime _selectedMonth;

  // Requests sub-tab (0: Leave Requests, 1: Late Attendance Requests)
  int _requestsSubTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Employee _resolveEmployee(User? user, List<Employee> liveEmployees) {
    final empId = user?.employeeId;
    final email = user?.email;
    final name = user?.name;
    final code = user?.employeeCode ?? user?.username;

    final emp = liveEmployees.where((e) {
      final codeNorm = e.code.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      final idNorm = e.id.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      final inputId = (empId ?? '').toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      final inputCode = (code ?? '').toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      final inputEmail = (email ?? '').toLowerCase().trim();
      final eEmail = e.email.toLowerCase().trim();

      return (inputEmail.isNotEmpty && eEmail == inputEmail) ||
          (inputId.isNotEmpty && (codeNorm == inputId || idNorm == inputId)) ||
          (inputCode.isNotEmpty && (codeNorm == inputCode || idNorm == inputCode));
    }).firstOrNull;

    if (emp != null) return emp;

    return Employee(
      id: empId ?? user?.id ?? 'EMP-001',
      code: code ?? empId ?? 'EMP001',
      name: (name != null && name.trim().isNotEmpty) ? name.trim() : 'Field Employee',
      department: (user?.department != null && user!.department!.trim().isNotEmpty)
          ? user.department!.trim()
          : 'Operations',
      designation: (user?.designation != null && user!.designation!.trim().isNotEmpty)
          ? user.designation!.trim()
          : 'Site Staff',
      type: EmployeeType.field,
      phone: (user?.phone != null && user!.phone!.trim().isNotEmpty) ? user.phone!.trim() : '',
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : 'employee@workpulse.io',
      status: EmployeeStatus.active,
      joiningDate: DateTime(2026, 1, 1),
      workLocation: 'Assigned Project Site',
      monthlyCtc: user?.monthlyCtc ?? 20000.0,
      annualCtc: (user?.monthlyCtc ?? 20000.0) * 12,
    );
  }

  Site? _resolveAssignedSite(
    Employee emp,
    List<EmployeeSiteMapping> mappings,
    List<Site> sites,
  ) {
    final empIdNorm = emp.id.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
    final empCodeNorm = emp.code.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();

    final activeMapping = mappings.where((m) {
      final mIdNorm = m.employeeId.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      return (mIdNorm == empIdNorm || mIdNorm == empCodeNorm) && m.status == MappingStatus.active;
    }).firstOrNull;

    if (activeMapping == null) {
      // If no explicit mapping, fallback to first available active site if single site exists
      return null;
    }

    return sites.where((s) => s.id == activeMapping.siteId).firstOrNull;
  }

  Map<String, dynamic> _computeTodayAttendance(
    Employee emp,
    List<DailyAttendance> allDaily,
    List<AttendancePunch> allPunches,
  ) {
    final now = _currentTime;
    final today = DateTime(now.year, now.month, now.day);

    final empNormId = emp.id.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
    final empNormCode = emp.code.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();

    bool isEmpMatch(String id) {
      final norm = id.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      return norm == empNormId || norm == empNormCode || (empNormCode.isNotEmpty && norm.contains(empNormCode));
    }

    final todayRecord = allDaily.where((d) =>
        isEmpMatch(d.employeeId) &&
        d.date.year == today.year &&
        d.date.month == today.month &&
        d.date.day == today.day
    ).firstOrNull;

    final todayPunches = allPunches.where((p) =>
        isEmpMatch(p.employeeId) &&
        p.timestamp.year == today.year &&
        p.timestamp.month == today.month &&
        p.timestamp.day == today.day
    ).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final inPunch = todayRecord?.firstPunch ??
        todayPunches.where((p) => p.type == PunchType.inPunch).firstOrNull;
    final outPunch = todayRecord?.lastPunch ??
        todayPunches.where((p) => p.type == PunchType.outPunch).lastOrNull;

    final hasPunchedIn = inPunch != null || (todayRecord != null && todayRecord.status != AttendanceStatus.absent);
    final hasPunchedOut = outPunch != null;

    final punchInStr = inPunch != null
        ? DateFormat('hh:mm a').format(inPunch.timestamp)
        : (hasPunchedIn ? '09:00 AM' : '--:--');

    final punchOutStr = outPunch != null
        ? DateFormat('hh:mm a').format(outPunch.timestamp)
        : (hasPunchedOut ? '06:00 PM' : '--:--');

    String totalHrsStr = '--';
    if (todayRecord != null && todayRecord.workingDuration.inMinutes > 0) {
      final hours = todayRecord.workingDuration.inMinutes ~/ 60;
      final mins = todayRecord.workingDuration.inMinutes % 60;
      totalHrsStr = '$hours.${mins.toString().padLeft(2, '0')}';
    } else if (inPunch != null && outPunch != null) {
      final diff = outPunch.timestamp.difference(inPunch.timestamp);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      totalHrsStr = '$h.${m.toString().padLeft(2, '0')}';
    } else if (inPunch != null) {
      final diff = now.difference(inPunch.timestamp);
      if (diff.inMinutes > 0) {
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        totalHrsStr = '$h.${m.toString().padLeft(2, '0')}';
      } else {
        totalHrsStr = '0.00';
      }
    }

    String statusLabel = 'NOT MARKED';
    Color statusColor = const Color(0xFF64748B);

    if (todayRecord != null) {
      switch (todayRecord.status) {
        case AttendanceStatus.present:
          statusLabel = 'PRESENT';
          statusColor = const Color(0xFF10B981);
          break;
        case AttendanceStatus.late:
          statusLabel = 'LATE';
          statusColor = const Color(0xFFF59E0B);
          break;
        case AttendanceStatus.leave:
          statusLabel = 'ON LEAVE';
          statusColor = const Color(0xFF8B5CF6);
          break;
        case AttendanceStatus.halfDay:
          statusLabel = 'HALF DAY';
          statusColor = const Color(0xFF06B6D4);
          break;
        case AttendanceStatus.absent:
          statusLabel = 'ABSENT';
          statusColor = const Color(0xFFEF4444);
          break;
        default:
          statusLabel = 'COMPLETED';
          statusColor = const Color(0xFF10B981);
      }
    } else if (hasPunchedIn) {
      statusLabel = inPunch != null && inPunch.timestamp.hour >= 10 ? 'LATE' : 'PRESENT';
      statusColor = statusLabel == 'LATE' ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    }

    return {
      'hasPunchedIn': hasPunchedIn,
      'hasPunchedOut': hasPunchedOut,
      'punchIn': punchInStr,
      'punchOut': punchOutStr,
      'totalHrs': totalHrsStr,
      'statusLabel': statusLabel,
      'statusColor': statusColor,
    };
  }

  Future<void> _refreshAllData() async {
    ref.invalidate(dailyAttendanceListProvider);
    ref.invalidate(allPunchesProvider);
    ref.invalidate(mappingsListProvider);
    ref.invalidate(sitesListProvider);
    ref.invalidate(employeesListProvider);
    ref.invalidate(notificationsListProvider);
    ref.invalidate(systemSettingsProvider);
    ref.invalidate(leaveRequestsProvider);
    ref.invalidate(regularizationRequestsProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _triggerPunchAction(bool isPunchOut, Employee emp) {
    context.push(
      '/field-verification',
      extra: {
        'isPunchOut': isPunchOut,
        'employeeId': emp.id,
      },
    ).then((_) {
      _refreshAllData();
      if (mounted) setState(() {});
    });
  }

  void _openFaceRegistration(Employee emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceRegistrationScreen(
          employeeId: emp.id,
          employeeName: emp.name,
          onCompleted: () {
            _refreshAllData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = ref.watch(authStateProvider);
    final liveEmployees = ref.watch(employeesListProvider).value ?? [];
    final allMappings = ref.watch(mappingsListProvider).value ?? [];
    final allSites = ref.watch(sitesListProvider).value ?? [];
    final allDaily = ref.watch(dailyAttendanceListProvider).value ?? [];
    final allPunches = ref.watch(allPunchesProvider).value ?? [];
    final notifications = ref.watch(notificationsListProvider).value ?? [];
    final systemSettings = ref.watch(systemSettingsProvider).value;

    final emp = _resolveEmployee(user, liveEmployees);
    final assignedSite = _resolveAssignedSite(emp, allMappings, allSites);
    final todayData = _computeTodayAttendance(emp, allDaily, allPunches);

    final unreadNotifs = notifications.where((n) => !n.isRead).length;
    final companyName = systemSettings?.companyName ?? 'Freelance Conscom';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E1B4B),
                    Color(0xFF0F172A),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE0F2FE), // very light cyan / blue
                    Color(0xFFEDE9FE), // soft lavender
                    Color(0xFFFCE7F3), // soft pink / purple
                  ],
                ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            color: const Color(0xFF6366F1),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    // Top App Header
                    _buildHeader(
                      emp: emp,
                      companyName: companyName,
                      unreadCount: unreadNotifs,
                      isDark: isDark,
                    ),

                    // Main Tab Content
                    Expanded(
                      child: IndexedStack(
                        index: _currentTab,
                        children: [
                          // Tab 0: Home Dashboard
                          _buildHomeTab(
                            emp: emp,
                            assignedSite: assignedSite,
                            todayData: todayData,
                            isDark: isDark,
                          ),

                          // Tab 1: Attendance History
                          _buildAttendanceHistoryTab(
                            emp: emp,
                            allDaily: allDaily,
                            allPunches: allPunches,
                            assignedSite: assignedSite,
                            isDark: isDark,
                          ),

                          // Tab 2: Requests (Leave & Late Attendance)
                          _buildRequestsTab(
                            emp: emp,
                            isDark: isDark,
                          ),

                          // Tab 3: Profile
                          _buildProfileTab(
                            emp: emp,
                            assignedSite: assignedSite,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeader({
    required Employee emp,
    required String companyName,
    required int unreadCount,
    required bool isDark,
  }) {
    final initials = emp.name.trim().isNotEmpty
        ? emp.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join()
        : 'EM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Profile Avatar
          InkWell(
            onTap: () => setState(() => _currentTab = 3),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Company & Employee Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  emp.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'ID: ${emp.code.isNotEmpty ? emp.code : emp.id}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Notification Icon with Badge
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 26,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => NotificationDrawer.show(context),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: HOME DASHBOARD
  // ==========================================
  Widget _buildHomeTab({
    required Employee emp,
    required Site? assignedSite,
    required Map<String, dynamic> todayData,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ATTENDANCE CARD (Coral / Orange Gradient)
          _buildAttendanceCard(todayData, isDark),

          const SizedBox(height: 18),

          // 2. SITE LOCATION CARD (Purple / Lavender Gradient)
          _buildSiteLocationCard(assignedSite, isDark),

          const SizedBox(height: 24),

          // 3. QUICK ACTIONS (2-Column Grid)
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickActionsGrid(emp, assignedSite, isDark),

          const SizedBox(height: 22),

          // 4. TODAY'S STATUS SECTION
          _buildTodayStatusCard(todayData, isDark),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7A59), // coral
            Color(0xFFFF5238), // warm vibrant orange
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5238).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Text(
                  data['statusLabel'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3 Columns: Punch In | Total Hrs | Punch Out
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Punch In',
                  value: data['punchIn'] as String,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Total Hrs',
                  value: data['totalHrs'] as String,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Punch Out',
                  value: data['punchOut'] as String,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSiteLocationCard(Site? site, bool isDark) {
    final hasSite = site != null;
    final siteName = hasSite ? site.name : 'No site assigned';
    final siteAddress = hasSite ? site.address : 'Please contact your administrator to map an active site';
    final geofenceRadius = hasSite ? '${site.geofenceRadius.toStringAsFixed(0)}m radius' : '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // indigo
            Color(0xFF8B5CF6), // purple
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Site Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Site Name
          Text(
            siteName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Site Address
          Text(
            siteAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.5,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          // Geofence Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hasSite ? const Color(0xFF34D399) : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  hasSite ? '● Inside Geofence ($geofenceRadius)' : '● Outside Geofence',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(Employee emp, Site? site, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildActionCard(
          title: 'Punch In',
          subtitle: 'Start shift with GPS',
          icon: Icons.login_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _triggerPunchAction(false, emp),
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Punch Out',
          subtitle: 'End shift attendance',
          icon: Icons.logout_rounded,
          color: const Color(0xFFF97316),
          onTap: () => _triggerPunchAction(true, emp),
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Face Registration',
          subtitle: 'Biometric capture',
          icon: Icons.face_retouching_natural_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => _openFaceRegistration(emp),
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Attendance History',
          subtitle: 'View monthly logs',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () => setState(() => _currentTab = 1),
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Leave Request',
          subtitle: 'Apply for paid/casual leave',
          icon: Icons.event_note_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () {
            setState(() {
              _currentTab = 2;
              _requestsSubTab = 0;
            });
            _showApplyLeaveModal(emp, isDark);
          },
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Late Attendance',
          subtitle: 'Submit regularization',
          icon: Icons.schedule_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () {
            setState(() {
              _currentTab = 2;
              _requestsSubTab = 1;
            });
            _showApplyRegularizationModal(emp, isDark);
          },
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Assigned Site',
          subtitle: site != null ? site.name : 'Check site details',
          icon: Icons.location_city_rounded,
          color: const Color(0xFF06B6D4),
          onTap: () => _showSiteDetailsModal(site, isDark),
          isDark: isDark,
        ),
        _buildActionCard(
          title: 'Profile',
          subtitle: 'View employee record',
          icon: Icons.badge_rounded,
          color: const Color(0xFF14B8A6),
          onTap: () => setState(() => _currentTab = 3),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(Map<String, dynamic> data, bool isDark) {
    final status = data['statusLabel'] as String;
    final color = data['statusColor'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Status: $status",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status == 'PRESENT'
                      ? 'Attendance successfully verified with site geofencing.'
                      : status == 'LATE'
                          ? 'Punch-in recorded after standard shift timing (09:00 AM).'
                          : 'Ensure to punch in within your assigned site perimeter.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: ATTENDANCE HISTORY
  // ==========================================
  Widget _buildAttendanceHistoryTab({
    required Employee emp,
    required List<DailyAttendance> allDaily,
    required List<AttendancePunch> allPunches,
    required Site? assignedSite,
    required bool isDark,
  }) {
    final empNormId = emp.id.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
    final empNormCode = emp.code.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();

    bool isEmpMatch(String id) {
      final norm = id.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
      return norm == empNormId || norm == empNormCode || (empNormCode.isNotEmpty && norm.contains(empNormCode));
    }

    // Filter records for selected month
    final monthRecords = allDaily.where((d) =>
        isEmpMatch(d.employeeId) &&
        d.date.year == _selectedMonth.year &&
        d.date.month == _selectedMonth.month
    ).toList()..sort((a, b) => b.date.compareTo(a.date));

    final presentDays = monthRecords.where((d) => d.status == AttendanceStatus.present).length;
    final lateDays = monthRecords.where((d) => d.status == AttendanceStatus.late).length;
    final totalMinutes = monthRecords.fold<int>(0, (sum, d) => sum + d.workingDuration.inMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Monthly Summary Pills
          Row(
            children: [
              Expanded(
                child: _buildSummaryPill('Present', '$presentDays Days', const Color(0xFF10B981), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryPill('Late', '$lateDays Days', const Color(0xFFF59E0B), isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryPill('Work Hours', '${totalHours}h', const Color(0xFF6366F1), isDark),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Attendance Records List
          if (monthRecords.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance records found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13.5),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthRecords.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final rec = monthRecords[i];
                final inPunchTime = rec.firstPunch?.timestamp;
                final outPunchTime = rec.lastPunch?.timestamp;
                final inTime = inPunchTime != null
                    ? DateFormat('hh:mm a').format(inPunchTime)
                    : '--:--';
                final outTime = outPunchTime != null
                    ? DateFormat('hh:mm a').format(outPunchTime)
                    : '--:--';
                final hours = (rec.workingDuration.inMinutes / 60).toStringAsFixed(1);
                final siteText = rec.firstPunch?.siteName ?? assignedSite?.name ?? 'Assigned Site';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Date Box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('dd').format(rec.date),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            Text(
                              DateFormat('EEE').format(rec.date),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // In / Out Times & Site
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$inTime - $outTime (${hours}h)',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              siteText,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rec.status == AttendanceStatus.present
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rec.status.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: rec.status == AttendanceStatus.present
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String title, String val, Color col, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: col),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: col),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: REQUESTS (LEAVE & LATE ATTENDANCE)
  // ==========================================
  Widget _buildRequestsTab({
    required Employee emp,
    required bool isDark,
  }) {
    final leavesAsync = ref.watch(employeeLeavesProvider(emp.id));
    final regularizationsAsync = ref.watch(employeeRegularizationsProvider(emp.id));

    return Column(
      children: [
        // Sub-tab Selector: [ Leave Requests ] | [ Late Attendance Requests ]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    title: 'Leave Requests',
                    index: 0,
                    icon: Icons.event_note_rounded,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    title: 'Late Attendance',
                    index: 1,
                    icon: Icons.schedule_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: _requestsSubTab == 0
              ? _buildLeavesList(leavesAsync, emp, isDark)
              : _buildRegularizationsList(regularizationsAsync, emp, isDark),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required int index,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _requestsSubTab == index;
    return InkWell(
      onTap: () => setState(() => _requestsSubTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeavesList(
    AsyncValue<List<LeaveRequest>> leavesAsync,
    Employee emp,
    bool isDark,
  ) {
    return leavesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Unable to load leave requests: $err')),
      data: (leaves) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Apply Button
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Apply for Leave', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showApplyLeaveModal(emp, isDark),
              ),
              const SizedBox(height: 16),

              if (leaves.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text('No leave requests found.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leaves.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final l = leaves[i];
                    final startStr = DateFormat('dd MMM').format(l.startDate);
                    final endStr = DateFormat('dd MMM yyyy').format(l.endDate);
                    final statusCol = l.status == LeaveStatus.approved
                        ? const Color(0xFF10B981)
                        : (l.status == LeaveStatus.rejected
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B));

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${l.leaveType} Leave',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusCol.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$startStr - $endStr (${l.totalDays.toInt()} Days)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (l.reason != null && l.reason!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${l.reason}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                          if (l.reviewRemarks != null && l.reviewRemarks!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusCol.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Remarks: ${l.reviewRemarks}',
                                style: TextStyle(fontSize: 11.5, color: statusCol, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegularizationsList(
    AsyncValue<List<RegularizationRequest>> regsAsync,
    Employee emp,
    bool isDark,
  ) {
    return regsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Unable to load late attendance requests: $err')),
      data: (regs) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Submit Late Attendance Request', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showApplyRegularizationModal(emp, isDark),
              ),
              const SizedBox(height: 16),

              if (regs.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text('No late attendance requests found.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: regs.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final r = regs[i];
                    final dateStr = DateFormat('dd MMM yyyy').format(r.attendanceDate);
                    final statusCol = r.status == RegularizationStatus.approved
                        ? const Color(0xFF10B981)
                        : (r.status == RegularizationStatus.rejected
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B));

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r.requestType,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusCol.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  r.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Date: $dateStr · ${r.requestedInTime} to ${r.requestedOutTime}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (r.remarks.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${r.remarks}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                          if (r.adminReviewRemarks != null && r.adminReviewRemarks!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusCol.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Response: ${r.adminReviewRemarks}',
                                style: TextStyle(fontSize: 11.5, color: statusCol, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: PROFILE
  // ==========================================
  Widget _buildProfileTab({
    required Employee emp,
    required Site? assignedSite,
    required bool isDark,
  }) {
    final initials = emp.name.trim().isNotEmpty
        ? emp.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join()
        : 'EM';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Photo & Name Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  emp.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  emp.designation,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '● Active Account',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Details List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              children: [
                _buildProfileRow('Employee Code', emp.code.isNotEmpty ? emp.code : 'EMP001', Icons.tag_rounded),
                const Divider(height: 20),
                _buildProfileRow('Employee ID', emp.id, Icons.badge_outlined),
                const Divider(height: 20),
                _buildProfileRow('Department', emp.department, Icons.business_rounded),
                const Divider(height: 20),
                _buildProfileRow('Assigned Site', assignedSite?.name ?? 'No site assigned', Icons.location_on_outlined),
                const Divider(height: 20),
                _buildProfileRow('Work Email', emp.email, Icons.email_outlined),
                const Divider(height: 20),
                _buildProfileRow('Contact Phone', emp.phone.isNotEmpty ? emp.phone : 'Not provided', Icons.phone_outlined),
                const Divider(height: 20),
                _buildProfileRow('Joining Date', DateFormat('dd MMM yyyy').format(emp.joiningDate), Icons.event_available_rounded),
                const Divider(height: 20),
                _buildProfileRow('Monthly CTC', '₹${NumberFormat('#,##0').format(emp.monthlyCtc)}', Icons.currency_rupee_rounded),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logout Button
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Sign Out from WorkPulse', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.12),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) => setState(() => _currentTab = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODALS
  // ==========================================
  void _showApplyLeaveModal(Employee emp, bool isDark) {
    String selectedLeaveType = 'CASUAL';
    DateTime fromDate = DateTime.now().add(const Duration(days: 1));
    DateTime toDate = DateTime.now().add(const Duration(days: 2));
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final days = toDate.difference(fromDate).inDays + 1;

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Apply for Leave',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Leave Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedLeaveType,
                    decoration: InputDecoration(
                      labelText: 'Leave Type',
                      prefixIcon: const Icon(Icons.category_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CASUAL', child: Text('Casual Leave (CL)')),
                      DropdownMenuItem(value: 'SICK', child: Text('Sick Leave (SL)')),
                      DropdownMenuItem(value: 'PAID', child: Text('Paid Earned Leave (EL)')),
                      DropdownMenuItem(value: 'UNPAID', child: Text('Loss of Pay (LOP)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedLeaveType = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Date Range Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: modalCtx,
                              initialDate: fromDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 7)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                fromDate = picked;
                                if (toDate.isBefore(fromDate)) toDate = fromDate;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'From Date',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(DateFormat('dd MMM yyyy').format(fromDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: modalCtx,
                              initialDate: toDate,
                              firstDate: fromDate,
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() => toDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'To Date',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(DateFormat('dd MMM yyyy').format(toDate)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Duration: $days Day(s)',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                  ),

                  const SizedBox(height: 12),

                  // Reason
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Reason for Leave',
                      hintText: 'e.g. Family function, medical consultation...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              await ref.read(leaveRequestsProvider.notifier).addLeave(
                                    employeeId: emp.id,
                                    leaveType: selectedLeaveType,
                                    startDate: fromDate,
                                    endDate: toDate,
                                    reason: reasonCtrl.text.trim().isNotEmpty
                                        ? reasonCtrl.text.trim()
                                        : 'Personal leave application',
                                  );

                              ref.invalidate(employeeLeavesProvider(emp.id));

                              if (!mounted) return;
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave request submitted successfully for approval!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Leave Request', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showApplyRegularizationModal(Employee emp, bool isDark) {
    String requestType = 'Late Punch IN';
    String reasonCategory = 'Traffic Delay';
    DateTime attDate = DateTime.now();
    String reqIn = '09:00 AM';
    String reqOut = '06:00 PM';
    final remarksCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Late Attendance Request',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Request Type
                  DropdownButtonFormField<String>(
                    value: requestType,
                    decoration: InputDecoration(
                      labelText: 'Request Type',
                      prefixIcon: const Icon(Icons.schedule_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Late Punch IN', child: Text('Late Punch IN (Traffic / Delay)')),
                      DropdownMenuItem(value: 'Missed Punch OUT', child: Text('Missed / Early Punch OUT')),
                      DropdownMenuItem(value: 'Both IN & OUT', child: Text('Both IN & OUT Regularization')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => requestType = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Attendance Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: modalCtx,
                        initialDate: attDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setModalState(() => attDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Attendance Date',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(DateFormat('dd MMMM yyyy').format(attDate)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Requested In & Out Times
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: reqIn,
                          decoration: InputDecoration(
                            labelText: 'Expected In',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) => reqIn = val,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: reqOut,
                          decoration: InputDecoration(
                            labelText: 'Expected Out',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) => reqOut = val,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Reason Category & Remarks
                  DropdownButtonFormField<String>(
                    value: reasonCategory,
                    decoration: InputDecoration(
                      labelText: 'Reason Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Traffic Delay', child: Text('Traffic Delay / Transport Issue')),
                      DropdownMenuItem(value: 'Client Meeting', child: Text('Client Site Visit / On Duty')),
                      DropdownMenuItem(value: 'Device / Network Glitch', child: Text('Device / Network Glitch')),
                      DropdownMenuItem(value: 'Medical Emergency', child: Text('Medical / Personal Emergency')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => reasonCategory = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: remarksCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Detailed Explanation',
                      hintText: 'Please describe the reason for late attendance...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            try {
                              final req = RegularizationRequest(
                                id: '',
                                employeeId: emp.id,
                                employeeCode: emp.code,
                                employeeName: emp.name,
                                department: emp.department,
                                requestType: requestType,
                                reasonCategory: reasonCategory,
                                attendanceDate: attDate,
                                requestedInTime: reqIn,
                                requestedOutTime: reqOut,
                                remarks: remarksCtrl.text.trim().isNotEmpty
                                    ? remarksCtrl.text.trim()
                                    : reasonCategory,
                                appliedAt: DateTime.now(),
                              );

                              await ref.read(regularizationRequestsProvider.notifier).addRequest(req);
                              ref.invalidate(employeeRegularizationsProvider(emp.id));

                              if (!mounted) return;
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Late attendance request submitted successfully!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Regularization Request', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSiteDetailsModal(Site? site, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_city_rounded, color: Color(0xFF6366F1), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                site != null ? site.name : 'Assigned Site Details',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: site != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModalSiteInfo('Client', site.client),
                  const SizedBox(height: 8),
                  _buildModalSiteInfo('Project', site.project),
                  const SizedBox(height: 8),
                  _buildModalSiteInfo('Address', site.address),
                  const SizedBox(height: 8),
                  _buildModalSiteInfo('Geofence Radius', '${site.geofenceRadius.toStringAsFixed(0)} meters'),
                  const SizedBox(height: 8),
                  _buildModalSiteInfo('Coordinates', '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}'),
                  const SizedBox(height: 8),
                  _buildModalSiteInfo('Site Manager', site.siteManagerName.isNotEmpty ? site.siteManagerName : 'Operations Lead'),
                ],
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('No active site mapping found for your profile. Please contact HR manager to assign your work location.'),
              ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModalSiteInfo(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
