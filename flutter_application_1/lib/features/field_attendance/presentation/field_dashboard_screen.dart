import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/aurora_background.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/regularization_request.dart';
import '../../../shared/models/site.dart';
import '../../employees/data/employee_repository.dart';
import '../../face_registration/data/face_registration_repository.dart';
import '../../face_registration/presentation/face_registration_screen.dart';
import '../../notifications/presentation/notification_drawer.dart';

class FieldDashboardScreen extends ConsumerStatefulWidget {
  const FieldDashboardScreen({super.key});

  @override
  ConsumerState<FieldDashboardScreen> createState() => _FieldDashboardScreenState();
}

class _FieldDashboardScreenState extends ConsumerState<FieldDashboardScreen> {
  int _currentTab = 0; // 0: Home, 1: Approvals, 2: Log, 3: Settings
  bool _showingProfileSubscreen = false;

  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  DateTime _selectedMonth = DateTime(2026, 8, 1);
  bool _isPunchedIn = true;
  String _todayPunchInTime = '09:15 AM';
  String _todayPunchOutTime = '--:--';
  bool _isRefreshingLocation = false;

  // Notification toggles
  bool _punchReminders = true;
  bool _geofenceAlerts = true;
  bool _approvalAlerts = true;

  // Mock approval requests list
  final List<Map<String, dynamic>> _requests = [
    {
      'title': 'Casual Leave',
      'type': 'Leave',
      'dates': '24 Aug - 25 Aug 2026',
      'reason': 'Personal errands & family event',
      'status': 'Approved',
      'statusColor': AppColors.present,
      'approver': 'Sarah Jenkins (HR)',
      'appliedOn': '22 Aug 2026',
    },
    {
      'title': 'Missed OUT Punch',
      'type': 'Attendance',
      'dates': '20 Aug 2026 (06:30 PM)',
      'reason': 'Device network glitch during checkout at CTS Campus',
      'status': 'Pending',
      'statusColor': AppColors.late,
      'approver': 'R Gayathri (Manager)',
      'appliedOn': '21 Aug 2026',
    },
    {
      'title': 'On Duty - Client Visit',
      'type': 'Attendance',
      'dates': '18 Aug 2026',
      'reason': 'Client site review at WTC Perungudi',
      'status': 'Approved',
      'statusColor': AppColors.present,
      'approver': 'Sarah Jenkins (HR)',
      'appliedOn': '17 Aug 2026',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Employee _getEmployeeDetails(String? employeeId, String? email, String? name, List<Employee> liveEmployees, String? department) {
    final searchPool = [...liveEmployees, ...MockEmployeeRepository.seedEmployees];
    final emp = searchPool.where((e) {
      final codeNorm = e.code.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      final idNorm = e.id.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      final inputId = (employeeId ?? '').toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      final inputEmail = (email ?? '').toLowerCase().trim();
      return (inputEmail.isNotEmpty && e.email.toLowerCase().trim() == inputEmail) ||
          (inputId.isNotEmpty && (codeNorm == inputId || idNorm == inputId)) ||
          (name != null && name.isNotEmpty && e.name.toLowerCase() == name.toLowerCase());
    }).firstOrNull;

    if (emp != null) return emp;

    // Dynamically build user profile from authenticated session
    return Employee(
      id: employeeId ?? 'EMP-001',
      code: employeeId ?? 'EMP001',
      name: (name != null && name.isNotEmpty) ? name : 'Field Staff Member',
      department: (department != null && department.isNotEmpty) ? department : 'FIELD OPERATIONS',
      designation: 'Field Staff Specialist',
      type: EmployeeType.field,
      phone: '9876543210',
      email: (email != null && email.isNotEmpty) ? email : 'field@workpulse.com',
      status: EmployeeStatus.active,
      joiningDate: DateTime(2026, 1, 1),
      workLocation: 'Assigned Client Project Sites',
      monthlyCtc: 45000.0,
      annualCtc: 540000.0,
    );
  }

  void _handlePunchAction(Employee emp) {
    context.push(
      '/field-verification',
      extra: {
        'isPunchOut': _isPunchedIn,
        'employeeId': emp.id,
      },
    ).then((_) {
      setState(() {
        _isPunchedIn = !_isPunchedIn;
        if (!_isPunchedIn) {
          _todayPunchOutTime = DateFormat('hh:mm a').format(DateTime.now());
        } else {
          _todayPunchInTime = DateFormat('hh:mm a').format(DateTime.now());
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPunchedIn ? 'Punch In recorded successfully!' : 'Punch Out recorded successfully!'),
          backgroundColor: AppColors.present,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final employeesAsync = ref.watch(employeesListProvider);
    final liveEmployees = employeesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <Employee>[],
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emp = _getEmployeeDetails(user?.employeeId, user?.email, user?.name, liveEmployees, user?.department);

    if (_showingProfileSubscreen) {
      return Scaffold(
        body: AuroraBackground(
          child: SafeArea(
            child: _buildProfileScreen(context, emp, isDark),
          ),
        ),
      );
    }

    return Scaffold(
      drawer: _buildAppDrawer(context, emp, isDark),
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top WorkPulse Header
              _buildTopAppBar(context, emp, isDark),

              // Main Tab Content
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildHomeTab(context, emp, isDark),
                    _buildApprovalsTab(context, emp, isDark),
                    _buildLogTab(context, emp, isDark),
                    _buildSettingsTab(context, emp, isDark),
                  ],
                ),
              ),

              // Bottom Curved Navigation Bar
              _buildCurvedBottomNav(isDark, emp),
            ],
          ),
        ),
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildTopAppBar(BuildContext context, Employee emp, bool isDark) {
    String title = 'WORKPULSE';
    if (_currentTab == 1) title = 'Approvals';
    if (_currentTab == 2) title = 'My Attendance Log';
    if (_currentTab == 3) title = 'Settings';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Navigation Menu',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            tooltip: 'Notifications',
            onPressed: () => _showNotificationsBottomSheet(context, isDark),
          ),
        ],
      ),
    );
  }

  // --- Tab 0: Home Tab ---
  Widget _buildHomeTab(BuildContext context, Employee emp, bool isDark) {
    final mappingsAsync = ref.watch(mappingsListProvider);
    final sitesAsync = ref.watch(sitesListProvider);
    final allRequests = ref.watch(regularizationRequestsProvider);

    // Find any regularization request for this employee
    final empRequests = allRequests.where((r) {
      final codeNorm = r.employeeCode.toLowerCase().replaceAll('-', '');
      final myCodeNorm = emp.code.toLowerCase().replaceAll('-', '');
      final idNorm = r.employeeId.toLowerCase().replaceAll('-', '');
      final myIdNorm = emp.id.toLowerCase().replaceAll('-', '');
      return codeNorm == myCodeNorm ||
          idNorm == myIdNorm ||
          r.employeeName.toLowerCase().contains(emp.name.toLowerCase()) ||
          emp.name.toLowerCase().contains(r.employeeName.toLowerCase());
    }).toList();

    RegularizationRequest? latestApproved;
    RegularizationRequest? latestPending;
    for (final r in empRequests) {
      if (r.status.isApproved && latestApproved == null) latestApproved = r;
      if (r.status.isPending && latestPending == null) latestPending = r;
    }

    final mappedSiteIds = mappingsAsync.maybeWhen(
      data: (list) => list
          .where((m) => m.employeeId == emp.id && m.isCurrentlyValid())
          .map((m) => m.siteId)
          .toList(),
      orElse: () => ['SITE-001'],
    );

    final targetSite = sitesAsync.maybeWhen(
      data: (list) => list.firstWhere(
        (s) => mappedSiteIds.contains(s.id),
        orElse: () => list.first,
      ),
      orElse: () => const Site(
        id: 'SITE-001',
        code: 'SITE001',
        name: 'CTS Chennai Campus',
        client: 'WorkPulse Enterprise',
        project: 'Campus Infrastructure',
        address: '5/535, Old Mahabalipuram Rd, Thoraipakkam, Chennai - 600097',
        latitude: 12.9463,
        longitude: 80.2372,
        geofenceRadius: 200,
        poNumber: 'PO-2026-001',
        siteManagerName: 'Sarah Jenkins',
        siteEngineerName: 'Alex Morgan',
        status: SiteStatus.active,
      ),
    );

    final effectivePunchIn = latestApproved != null
        ? latestApproved.requestedInTime
        : (latestPending != null ? 'Pending (${latestPending.requestedInTime})' : _todayPunchInTime);
    final effectivePunchOut = latestApproved != null
        ? latestApproved.requestedOutTime
        : (latestPending != null ? 'Pending (${latestPending.requestedOutTime})' : _todayPunchOutTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Employee Punch Card
          GlassmorphicContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emp.designation,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _showingProfileSubscreen = true),
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Big Glowing Action Button (Time Out / Time In)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _handlePunchAction(emp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B), // Vibrant Amber
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: const Color(0xFFF59E0B).withOpacity(0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isPunchedIn ? Icons.logout_rounded : Icons.login_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _isPunchedIn ? 'Time Out' : 'Time In',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Late Punch Status Notice (If Approved or Pending)
          if (latestApproved != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.present.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.present.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.present.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppColors.present, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Late Attendance Approved by ${latestApproved.reviewedBy ?? "HR/Admin"}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.present),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Punches marked: IN (${latestApproved.requestedInTime}) • OUT (${latestApproved.requestedOutTime}) • ${latestApproved.adminReviewRemarks ?? "Approved"}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (latestPending != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Late Punch Sent for HR/Admin Review',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Requested: IN (${latestPending.requestedInTime}), OUT (${latestPending.requestedOutTime}). Remarks forwarded to HR & Admin.',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Your Location Card (Only Displays Mapped Place Name)
          GlassmorphicContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: _isRefreshingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Refresh Location',
                      onPressed: () async {
                        setState(() => _isRefreshingLocation = true);
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          setState(() => _isRefreshingLocation = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Location refreshed: ${targetSite.name}')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _isRefreshingLocation
                        ? 'Fetching location...'
                        : targetSite.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Today's Work Summary Card
          GlassmorphicContainer(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Activity • ${DateFormat('dd MMMM yyyy').format(_currentTime)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('PUNCH IN', effectivePunchIn, AppColors.present, isDark),
                    _buildSummaryItem('PUNCH OUT', effectivePunchOut, const Color(0xFFF59E0B), isDark),
                    _buildSummaryItem('TOTAL HOURS', '08:35 hrs', AppColors.primary, isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  // --- Tab 1: Approvals Tab ---
  Widget _buildApprovalsTab(BuildContext context, Employee emp, bool isDark) {
    final liveRequests = ref.watch(regularizationRequestsProvider);
    final empLiveRequests = liveRequests.where((r) {
      final codeNorm = r.employeeCode.toLowerCase().replaceAll('-', '');
      final myCodeNorm = emp.code.toLowerCase().replaceAll('-', '');
      final idNorm = r.employeeId.toLowerCase().replaceAll('-', '');
      final myIdNorm = emp.id.toLowerCase().replaceAll('-', '');
      return codeNorm == myCodeNorm ||
          idNorm == myIdNorm ||
          r.employeeName.toLowerCase().contains(emp.name.toLowerCase()) ||
          emp.name.toLowerCase().contains(r.employeeName.toLowerCase());
    }).toList();

    // Map live provider requests into list items
    final dynamicList = <Map<String, dynamic>>[
      ...empLiveRequests.map((r) {
        Color statusColor = const Color(0xFFF59E0B);
        if (r.status.isApproved) statusColor = AppColors.present;
        if (r.status.isRejected) statusColor = AppColors.absent;

        return {
          'title': r.requestType,
          'type': r.reasonCategory,
          'dates': '${DateFormat('dd MMM yyyy').format(r.attendanceDate)} (${r.requestedInTime} - ${r.requestedOutTime})',
          'reason': r.remarks,
          'status': r.status.isApproved
              ? 'Approved (Marked)'
              : (r.status.isRejected ? 'Rejected' : 'Pending HR/Admin Review'),
          'statusColor': statusColor,
          'approver': r.reviewedBy ?? 'Sarah Jenkins (HR) & Admin',
          'appliedOn': DateFormat('dd MMM yyyy').format(r.appliedAt),
        };
      }),
      ..._requests,
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildApprovalOptionCard(
              icon: Icons.directions_walk_rounded,
              title: 'Leave',
              subtitle: 'Casual: 4 | Sick: 6 | Earned: 12 available',
              isDark: isDark,
              onTap: () => _showLeaveBalanceModal(context, isDark),
            ),
            const SizedBox(height: 12),
            _buildApprovalOptionCard(
              icon: Icons.event_available_rounded,
              title: 'Attendance',
              subtitle: 'Regularization & missed punches',
              isDark: isDark,
              onTap: () => _showAttendanceRegularizationModal(context, isDark),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Requests',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '${dynamicList.length} Total',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dynamicList.map((req) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _showRequestDetailModal(context, req, isDark),
                    borderRadius: BorderRadius.circular(14),
                    child: GlassmorphicContainer(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req['title'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req['dates'],
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (req['statusColor'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (req['statusColor'] as Color).withOpacity(0.4)),
                            ),
                            child: Text(
                              req['status'],
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: req['statusColor'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 80),
          ],
        ),

        // Floating "+ Request" Button
        Positioned(
          bottom: 24,
          right: 20,
          child: ElevatedButton.icon(
            onPressed: () => _showNewRequestDialog(context, isDark),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text(
              'Request',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              shadowColor: const Color(0xFFF59E0B).withOpacity(0.45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // --- Tab 2: Attendance Log Tab (Calendar View) ---
  Widget _buildLogTab(BuildContext context, Employee emp, bool isDark) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary Banner
              GlassmorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total Undertime: ',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          '-05:16 hrs',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.absent),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Calculated against monthly standard 176 work hours.',
                          child: Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 22),
                      tooltip: 'Download Monthly PDF',
                      onPressed: () => _showPdfExportDialog(context, isDark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calendar Card
              GlassmorphicContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Column(
                  children: [
                    // Month Navigation
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

                    // Weekdays Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const Divider(height: 20),

                    // Calendar Grid
                    _buildCalendarGrid(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // Floating Refresh Button
        Positioned(
          bottom: 24,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFF59E0B),
            mini: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance logs synced with WorkPulse cloud server.')),
              );
            },
            child: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final daysInMonth = 31;
    final startWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    List<Widget> cells = [];

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final weekday = (startWeekday + day - 1) % 7;
      final isSunday = weekday == 0;
      final isHoliday = (day == 3 || day == 15);
      final isAbsent = (day == 17 || day == 20);
      final isHalfDay = (day == 6 || day == 19);
      final isFuture = day > 24;

      Color bgColor = AppColors.present; // Green (Present)
      Color textColor = Colors.white;

      if (isFuture) {
        bgColor = Colors.transparent;
        textColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
      } else if (isSunday) {
        bgColor = Colors.grey.withOpacity(0.35);
      } else if (isHoliday) {
        bgColor = const Color(0xFFF59E0B).withOpacity(0.25);
      } else if (isAbsent) {
        bgColor = AppColors.absent;
      } else if (isHalfDay) {
        bgColor = const Color(0xFF06B6D4); // Cyan
      }

      cells.add(
        InkWell(
          onTap: isFuture
              ? null
              : () => _showDayDetailBottomSheet(day, isHoliday, isAbsent, isHalfDay, isSunday),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isHoliday
                  ? const Text('🏖️', style: TextStyle(fontSize: 14))
                  : Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  // --- Tab 3: Settings Tab ---
  Widget _buildSettingsTab(BuildContext context, Employee emp, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsItem(
          icon: Icons.domain_rounded,
          title: 'Organization',
          subtitle: 'WorkPulse Enterprise details',
          isDark: isDark,
          onTap: () => _showOrganizationModal(context, isDark),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Alerts & punch reminders',
          isDark: isDark,
          onTap: () => _showNotificationSettingsModal(context, isDark),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.face_rounded,
          title: 'Face ID',
          subtitle: 'Biometric Face ID registration',
          isDark: isDark,
          onTap: () => _showFaceIdModal(context, isDark),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.person_outline_rounded,
          title: 'Profile',
          subtitle: 'View Profile',
          isDark: isDark,
          onTap: () {
            setState(() => _showingProfileSubscreen = true);
          },
        ),
        const SizedBox(height: 24),
        _buildSettingsItem(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          subtitle: 'End session and return to login',
          isDark: isDark,
          iconColor: AppColors.absent,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        borderRadius: 16,
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // --- Subscreen: My Profile ---
  Widget _buildProfileScreen(BuildContext context, Employee emp, bool isDark) {
    return Stack(
      children: [
        Column(
          children: [
            // WorkPulse Gradient Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => setState(() => _showingProfileSubscreen = false),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'My Profile',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Top Avatar Header Card
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'P',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emp.designation,
                                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      emp.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile Information Details Card
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const Divider(height: 20),
                        _buildProfileField('Employee Code', emp.code),
                        _buildProfileField('Full Name', emp.name),
                        _buildProfileField('Phone', emp.phone),
                        _buildProfileField('Date of Joining', DateFormat('dd-MMM-yyyy').format(emp.joiningDate)),
                        _buildProfileField('Division', 'WorkPulse Enterprise'),
                        _buildProfileField('Role', 'Standard User'),
                        _buildProfileField('Location', emp.workLocation),
                        _buildProfileField('Department', emp.department),
                        _buildProfileField('Designation', emp.designation),
                        _buildProfileField('Shift', 'Flexi Timing - Office'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Biometric Face Registration Card
                  Consumer(
                    builder: (context, ref, _) {
                      final faceStatusAsync = ref.watch(faceRegistrationStatusProvider(emp.id));
                      final faceStatus = faceStatusAsync.valueOrNull;
                      final isRegistered = faceStatus?.isRegistered ?? (emp.isFaceRegistered ?? false);

                      return GlassmorphicContainer(
                        padding: const EdgeInsets.all(18),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.face_retouching_natural_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Face Biometrics & Attendance',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isRegistered ? AppColors.present : Colors.amber).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (isRegistered ? AppColors.present : Colors.amber).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isRegistered ? '✓ Registered' : '⚠ Not Registered',
                                    style: TextStyle(
                                      color: isRegistered ? AppColors.present : Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              isRegistered
                                  ? 'Your face template is active for verified geofenced attendance capture.'
                                  : 'Register your face to enable mobile biometric clock-in and anti-spoof attendance verification.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            if (faceStatus?.registeredAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Registered: ${DateFormat('dd MMM yyyy, hh:mm a').format(faceStatus!.registeredAt!)} (${faceStatus.modelVersion ?? "v1.0"})',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => FaceRegistrationScreen(
                                      employeeId: emp.id,
                                      employeeName: emp.name,
                                      onCompleted: () {
                                        ref.invalidate(faceRegistrationStatusProvider(emp.id));
                                        ref.invalidate(employeesListProvider);
                                      },
                                    ),
                                  );
                                },
                                icon: Icon(
                                  isRegistered ? Icons.refresh_rounded : Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isRegistered ? 'Re-register Face' : 'Register Face Now',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRegistered ? const Color(0xFF3B82F6) : AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Reporting to Card
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reporting to',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.secondary.withOpacity(0.2),
                              child: const Text('RG', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('R Gayathri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('(FAG-Head)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),

        // Floating QR Code button
        Positioned(
          bottom: 24,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFF59E0B),
            onPressed: () => _showQrCodeModal(context, emp, isDark),
            child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // --- Bottom Curved Navigation Bar ---
  Widget _buildCurvedBottomNav(bool isDark, Employee emp) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTabItem(0, Icons.home_outlined, 'Home'),
          _buildNavTabItem(1, Icons.check_circle_outline_rounded, 'Approvals'),

          // Center Elevated Gradient FAB Button (Quick Punch)
          InkWell(
            onTap: () => _handlePunchAction(emp),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 26),
            ),
          ),

          _buildNavTabItem(2, Icons.calendar_month_outlined, 'Log'),
          _buildNavTabItem(3, Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavTabItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    const activeColor = AppColors.primary;
    final inactiveColor = Colors.grey[500];

    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = index;
          _showingProfileSubscreen = false;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Modals & Dialogs ---
  Widget _buildAppDrawer(BuildContext context, Employee emp, bool isDark) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            accountName: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            accountEmail: Text(emp.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'W',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: const Text('Approvals'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('My Attendance Log'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _showingProfileSubscreen = true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTab = 3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.absent),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.absent, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _confirmSignOut(context);
            },
          ),
        ],
      ),
    );
  }

  void _showNewRequestDialog(BuildContext context, bool isDark, {String initialType = 'Attendance Regularization (Missed Punch)'}) {
    String selectedType = initialType;
    final reasonController = TextEditingController();
    DateTime attendanceDate = DateTime.now();
    TimeOfDay inTime = const TimeOfDay(hour: 9, minute: 15);
    TimeOfDay outTime = const TimeOfDay(hour: 18, minute: 30);
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 1));
    String regularizationReason = 'Forgot to Punch IN';
    String leaveSession = 'Full Day';
    String permissionReason = 'Personal Emergency';
    TimeOfDay permFromTime = const TimeOfDay(hour: 14, minute: 0);
    TimeOfDay permToTime = const TimeOfDay(hour: 16, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            selectedType.contains('Attendance') || selectedType.contains('Duty')
                                ? Icons.access_time_filled_rounded
                                : (selectedType.contains('Permission') ? Icons.timer_rounded : Icons.calendar_today_rounded),
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text('New Request / Regulation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Request Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Request Category',
                      prefixIcon: Icon(Icons.category_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Attendance Regularization (Missed Punch)',
                        child: Text('Attendance Regularization (Missed Punch)'),
                      ),
                      DropdownMenuItem(
                        value: 'Attendance Regularization (Shift Time Correction)',
                        child: Text('Attendance Regularization (Time Correction)'),
                      ),
                      DropdownMenuItem(
                        value: 'On Duty / Official Client Visit',
                        child: Text('On Duty / Official Client Visit'),
                      ),
                      DropdownMenuItem(
                        value: 'Permission (Short Hours)',
                        child: Text('Permission (Short Hours)'),
                      ),
                      DropdownMenuItem(
                        value: 'Casual Leave (CL)',
                        child: Text('Casual Leave (CL)'),
                      ),
                      DropdownMenuItem(
                        value: 'Sick Leave (SL)',
                        child: Text('Sick Leave (SL)'),
                      ),
                      DropdownMenuItem(
                        value: 'Earned Leave (EL)',
                        child: Text('Earned Leave (EL)'),
                      ),
                      DropdownMenuItem(
                        value: 'Compensatory Off',
                        child: Text('Compensatory Off'),
                      ),
                    ],
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setModalState(() => selectedType = newVal);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Section 1: Attendance Regularization / On Duty
                  if (selectedType.contains('Attendance') || selectedType.contains('Duty')) ...[
                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: attendanceDate,
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2026, 12, 31),
                        );
                        if (picked != null) setModalState(() => attendanceDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Attendance Date',
                          prefixIcon: Icon(Icons.calendar_month_rounded, size: 20),
                        ),
                        child: Text(DateFormat('dd MMMM yyyy (EEEE)').format(attendanceDate)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time Pickers (In Time & Out Time)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: inTime,
                              );
                              if (picked != null) setModalState(() => inTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-In Time',
                                prefixIcon: Icon(Icons.login_rounded, color: AppColors.present, size: 20),
                              ),
                              child: Text(inTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: outTime,
                              );
                              if (picked != null) setModalState(() => outTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-Out Time',
                                prefixIcon: Icon(Icons.logout_rounded, color: Color(0xFFF59E0B), size: 20),
                              ),
                              child: Text(outTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Regularization Reason Category Dropdown
                    DropdownButtonFormField<String>(
                      value: regularizationReason,
                      decoration: const InputDecoration(
                        labelText: 'Regularization Reason Dropdown',
                        prefixIcon: Icon(Icons.rule_rounded, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Forgot to Punch IN', child: Text('Forgot to Punch IN')),
                        DropdownMenuItem(value: 'Forgot to Punch OUT', child: Text('Forgot to Punch OUT')),
                        DropdownMenuItem(
                          value: 'Out of Geofence (Client Site - Contact HR/Admin)',
                          child: Text('Out of Geofence (Contact HR/Admin)'),
                        ),
                        DropdownMenuItem(
                          value: 'Network / Device Glitch during Punch',
                          child: Text('Network / Device Glitch'),
                        ),
                        DropdownMenuItem(
                          value: 'Biometric Kiosk Error',
                          child: Text('Biometric Kiosk Error'),
                        ),
                        DropdownMenuItem(
                          value: 'Late Arrival with Permission',
                          child: Text('Late Arrival with Permission'),
                        ),
                        DropdownMenuItem(value: 'Official External Meeting', child: Text('Official External Meeting')),
                        DropdownMenuItem(value: 'Other Reason', child: Text('Other Specific Reason')),
                      ],
                      onChanged: (newVal) {
                        if (newVal != null) setModalState(() => regularizationReason = newVal);
                      },
                    ),
                  ]

                  // Dynamic Section 2: Permission Hours
                  else if (selectedType.contains('Permission')) ...[
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: attendanceDate,
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2026, 12, 31),
                        );
                        if (picked != null) setModalState(() => attendanceDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Permission Date',
                          prefixIcon: Icon(Icons.calendar_month_rounded, size: 20),
                        ),
                        child: Text(DateFormat('dd MMMM yyyy').format(attendanceDate)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: permFromTime);
                              if (picked != null) setModalState(() => permFromTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'From Time', prefixIcon: Icon(Icons.timer_outlined, size: 20)),
                              child: Text(permFromTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: permToTime);
                              if (picked != null) setModalState(() => permToTime = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'To Time', prefixIcon: Icon(Icons.timer_off_outlined, size: 20)),
                              child: Text(permToTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: permissionReason,
                      decoration: const InputDecoration(labelText: 'Permission Purpose', prefixIcon: Icon(Icons.help_outline_rounded, size: 20)),
                      items: const [
                        DropdownMenuItem(value: 'Personal Emergency', child: Text('Personal Emergency')),
                        DropdownMenuItem(value: 'Medical Checkup', child: Text('Medical Checkup')),
                        DropdownMenuItem(value: 'Official Bank / Client Work', child: Text('Official Bank / Client Work')),
                        DropdownMenuItem(value: 'Transport Delay', child: Text('Transport / Traffic Delay')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => permissionReason = val);
                      },
                    ),
                  ]

                  // Dynamic Section 3: Leave (Casual, Sick, Earned)
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fromDate,
                                firstDate: DateTime(2026, 1, 1),
                                lastDate: DateTime(2026, 12, 31),
                              );
                              if (picked != null) setModalState(() => fromDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'From Date', prefixIcon: Icon(Icons.event_rounded, size: 20)),
                              child: Text(DateFormat('dd MMM yyyy').format(fromDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: toDate,
                                firstDate: fromDate,
                                lastDate: DateTime(2026, 12, 31),
                              );
                              if (picked != null) setModalState(() => toDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'To Date', prefixIcon: Icon(Icons.event_busy_rounded, size: 20)),
                              child: Text(DateFormat('dd MMM yyyy').format(toDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: leaveSession,
                      decoration: const InputDecoration(labelText: 'Leave Duration / Session', prefixIcon: Icon(Icons.timelapse_rounded, size: 20)),
                      items: const [
                        DropdownMenuItem(value: 'Full Day', child: Text('Full Day (100% Shift)')),
                        DropdownMenuItem(value: 'First Half (Morning)', child: Text('First Half (09:00 AM - 01:30 PM)')),
                        DropdownMenuItem(value: 'Second Half (Afternoon)', child: Text('Second Half (01:30 PM - 06:00 PM)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => leaveSession = val);
                      },
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Reason / Justification Notes
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Justification / Remarks',
                      hintText: 'Enter detailed reason for HR and Manager review',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Submit Regulation / Request',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    onPressed: () {
                      String dateStr = '';
                      String detailReason = '';

                      if (selectedType.contains('Attendance') || selectedType.contains('Duty')) {
                        dateStr = '${DateFormat('dd MMM yyyy').format(attendanceDate)} (${inTime.format(context)} - ${outTime.format(context)})';
                        detailReason = '$regularizationReason: ${reasonController.text.isEmpty ? "Shift hours regularized by employee" : reasonController.text}';
                      } else if (selectedType.contains('Permission')) {
                        dateStr = '${DateFormat('dd MMM yyyy').format(attendanceDate)} (${permFromTime.format(context)} - ${permToTime.format(context)})';
                        detailReason = '$permissionReason: ${reasonController.text.isEmpty ? "Short permission requested" : reasonController.text}';
                      } else {
                        dateStr = '${DateFormat('dd MMM').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)} ($leaveSession)';
                        detailReason = reasonController.text.isEmpty ? 'Scheduled leave requirement' : reasonController.text;
                      }

                      setState(() {
                        _requests.insert(0, {
                          'title': selectedType,
                          'type': selectedType.contains('Leave') ? 'Leave' : 'Attendance',
                          'dates': dateStr,
                          'reason': detailReason,
                          'status': 'Pending',
                          'statusColor': AppColors.late,
                          'approver': 'Sarah Jenkins (HR) & R Gayathri (Manager)',
                          'appliedOn': DateFormat('dd MMM yyyy').format(DateTime.now()),
                        });
                      });

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Regulation request submitted successfully to HR & Admin!'),
                          backgroundColor: AppColors.present,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRequestDetailModal(BuildContext context, Map<String, dynamic> req, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(req['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (req['statusColor'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(req['status'], style: TextStyle(color: req['statusColor'] as Color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildProfileField('Dates', req['dates']),
            _buildProfileField('Category', req['type']),
            _buildProfileField('Reason / Remarks', req['reason']),
            _buildProfileField('Approver', req['approver'] ?? 'Sarah Jenkins (HR) & Admin'),
            _buildProfileField('Applied On', req['appliedOn'] ?? '22 Aug 2026'),
            const SizedBox(height: 16),
            if (req['status'] == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.absent),
                      onPressed: () {
                        setState(() {
                          req['status'] = 'Rejected';
                          req['statusColor'] = AppColors.absent;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request rejected by HR/Admin.')),
                        );
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.present),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Approve Late Attendance',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        setState(() {
                          req['status'] = 'Approved (Late Attendance Marked)';
                          req['statusColor'] = AppColors.present;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Late attendance approved! Employee record updated to Present/Late.'),
                            backgroundColor: AppColors.present,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveBalanceModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave Balances (2026)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            _buildProfileField('Casual Leave (CL)', '4 Days Available (Used: 2)'),
            _buildProfileField('Sick Leave (SL)', '6 Days Available (Used: 0)'),
            _buildProfileField('Earned Leave (EL)', '12 Days Available (Used: 3)'),
            _buildProfileField('Optional Holiday', '1 Day Available'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showNewRequestDialog(context, isDark, initialType: 'Casual Leave (CL)');
                },
                child: const Text('Apply for Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceRegularizationModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Regularization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            const Text('Select a missed punch, out-of-geofence, or absent day from your log to request manager and HR correction.'),
            const SizedBox(height: 14),
            _buildProfileField('Pending Regularizations', '1 Request (20 Aug)'),
            _buildProfileField('Approved Regularizations', '3 Requests this month'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showNewRequestDialog(context, isDark, initialType: 'Attendance Regularization (Missed Punch)');
                },
                child: const Text('Regularize Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettingsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Divider(height: 20),
              SwitchListTile(
                title: const Text('Punch In / Out Reminders'),
                subtitle: const Text('Remind 15 mins before scheduled shift'),
                value: _punchReminders,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setModalState(() => _punchReminders = val);
                  setState(() => _punchReminders = val);
                },
              ),
              SwitchListTile(
                title: const Text('Geofence Arrival Alerts'),
                subtitle: const Text('Notify when entering mapped approved site perimeter'),
                value: _geofenceAlerts,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setModalState(() => _geofenceAlerts = val);
                  setState(() => _geofenceAlerts = val);
                },
              ),
              SwitchListTile(
                title: const Text('Approval Status Notifications'),
                subtitle: const Text('Instant notification when manager approves leave'),
                value: _approvalAlerts,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setModalState(() => _approvalAlerts = val);
                  setState(() => _approvalAlerts = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrganizationModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Organization Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            _buildProfileField('Company', 'WorkPulse Enterprise HR Solutions'),
            _buildProfileField('Headquarters', 'Chennai Tech Corridor HQ'),
            _buildProfileField('Working Days', 'Monday - Friday (5 Days)'),
            _buildProfileField('Standard Shift', '09:00 AM - 06:00 PM (Flexi Timing)'),
            _buildProfileField('HR Support', 'hr@workpulse.io'),
          ],
        ),
      ),
    );
  }

  void _showFaceIdModal(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.face_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Face ID Registration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.present, size: 52),
            ),
            const SizedBox(height: 14),
            const Text(
              'Biometric Face ID is active and enrolled for WorkPulse mobile kiosk terminals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Biometric Face Template re-synced!')),
              );
            },
            child: const Text('Re-scan Face'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPdfExportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Export Monthly Timesheet'),
          ],
        ),
        content: const Text(
          'Download official August 2026 Attendance & Payroll Log PDF generated by WorkPulse HR Engine.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('August_2026_Attendance_Report.pdf downloaded successfully!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayDetailBottomSheet(int day, bool isHoliday, bool isAbsent, bool isHalfDay, bool isSunday) {
    String status = isHoliday ? 'Holiday' : (isSunday ? 'Weekly Off' : (isAbsent ? 'Absent' : (isHalfDay ? 'Half Day' : 'Present')));
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: $day August 2026', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isAbsent ? AppColors.absent : (isHalfDay ? AppColors.late : AppColors.present)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isAbsent ? AppColors.absent : (isHalfDay ? AppColors.late : AppColors.present),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (!isSunday && !isHoliday && !isAbsent) ...[
              _buildProfileField('In Time', '09:12 AM'),
              _buildProfileField('Out Time', '06:15 PM'),
              _buildProfileField('Total Working Duration', '09 hrs 03 mins'),
              _buildProfileField('Location', 'CTS Chennai Campus'),
            ] else if (isAbsent) ...[
              _buildProfileField('Reason', 'Unscheduled Absence'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showNewRequestDialog(context, false, initialType: 'Attendance Regularization (Missed Punch)');
                  },
                  child: const Text('Request Regularization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else if (isHoliday) ...[
              _buildProfileField('Holiday Name', day == 15 ? 'Independence Day' : 'Special Corporate Holiday'),
            ],
          ],
        ),
      ),
    );
  }

  void _showQrCodeModal(BuildContext context, Employee emp, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(child: Text('WorkPulse Digital ID Card')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('${emp.code} • ${emp.department}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, bool isDark) {
    NotificationDrawer.show(context);
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of your WorkPulse workspace?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
