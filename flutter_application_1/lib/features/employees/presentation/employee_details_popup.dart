import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../face_registration/data/face_registration_repository.dart';
import '../../face_registration/presentation/face_registration_screen.dart';

class EmployeeDetailsPopup extends ConsumerStatefulWidget {
  final String? employeeId;
  final Employee? employee;
  final VoidCallback? onEdit;

  const EmployeeDetailsPopup({
    super.key,
    this.employeeId,
    this.employee,
    this.onEdit,
  }) : assert(employeeId != null || employee != null, 'Either employeeId or employee must be provided');

  static Future<void> show(BuildContext context, {String? employeeId, Employee? employee, VoidCallback? onEdit}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EmployeeDetailsPopup(employeeId: employeeId, employee: employee, onEdit: onEdit),
    );
  }

  @override
  ConsumerState<EmployeeDetailsPopup> createState() => _EmployeeDetailsPopupState();
}

class _EmployeeDetailsPopupState extends ConsumerState<EmployeeDetailsPopup> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Overview',
    'Personal',
    'Employment',
    'Contact',
    'Attendance',
    'Sites',
    'Mapping History',
    'Audit History',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return employeesAsync.when(
      loading: () => const Dialog(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))),
      error: (err, _) => Dialog(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: $err'))),
      data: (allEmployees) {
        final targetId = widget.employee?.id ?? widget.employeeId;
        final emp = allEmployees.where((e) => e.id.toLowerCase() == targetId?.toLowerCase()).firstOrNull ?? widget.employee;

        if (emp == null) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Employee profile not found.'),
            ),
          );
        }

        final screenSize = MediaQuery.sizeOf(context);
        final dialogWidth = screenSize.width < 960 ? screenSize.width * 0.95 : 920.0;
        final dialogHeight = screenSize.height < 760 ? screenSize.height * 0.92 : 720.0;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: screenSize.width < 500 ? 22 : 30,
                      backgroundColor: emp.type.isOffice ? Colors.indigo.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                      child: Text(
                        emp.code.length > 2 ? emp.code.substring(0, 2) : emp.code,
                        style: TextStyle(
                          fontSize: screenSize.width < 500 ? 13 : 18,
                          fontWeight: FontWeight.bold,
                          color: emp.type.isOffice ? Colors.indigo : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                emp.name,
                                style: TextStyle(fontSize: screenSize.width < 500 ? 16 : 20, fontWeight: FontWeight.w800),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: emp.status.isActive ? AppColors.present.withOpacity(0.12) : AppColors.absent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  emp.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: emp.status.isActive ? AppColors.present : AppColors.absent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${emp.designation} · ${emp.department} · ${emp.code}',
                            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                emp.type.isOffice ? Icons.fingerprint_rounded : Icons.gps_fixed_rounded,
                                size: 14,
                                color: emp.type.isOffice ? Colors.indigo : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  emp.type.isOffice
                                      ? 'Biometric: ${emp.biometricId ?? "BIO-Default"}'
                                      : 'Mobile GPS Punch (Geofenced)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: emp.type.isOffice ? Colors.indigo : AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8 Profile Tabs Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(emp, isDark),
                      _buildPersonalTab(emp, isDark),
                      _buildEmploymentTab(emp, isDark),
                      _buildContactTab(emp, isDark),
                      _buildAttendanceTab(emp, isDark),
                      _buildSitesTab(emp, isDark),
                      _buildMappingHistoryTab(emp, isDark),
                      _buildAuditHistoryTab(emp, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Tab 1: Overview ---
  Widget _buildOverviewTab(Employee emp, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMiniMetric('Staff Role', emp.type.displayName, Colors.blue, isDark),
              const SizedBox(width: 12),
              _buildMiniMetric('Attendance Source', emp.type.isOffice ? 'Biometric Terminal' : 'Mobile GPS', AppColors.primary, isDark),
              const SizedBox(width: 12),
              _buildMiniMetric('Joined', DateFormat('dd-MMM-yyyy').format(emp.joiningDate), Colors.teal, isDark),
              const SizedBox(width: 12),
              _buildMiniMetric('Portal Access', emp.portalAccess ? 'Enabled' : 'Disabled', AppColors.present, isDark),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoCard('Primary Contact & Identity', [
            _buildFieldRow('Official Work Email', emp.officialEmail ?? emp.email),
            _buildFieldRow('Primary Contact Phone', emp.phone),
            _buildFieldRow('Work Location Base', emp.workLocation),
            _buildFieldRow('Residential Address', emp.address.isNotEmpty ? emp.address : 'N/A'),
          ], isDark),
          const SizedBox(height: 14),
          _buildInfoCard('Attendance & Compliance Profile', [
            _buildFieldRow('Authentication Protocol', emp.type.isOffice ? 'Physical Biometric Fingerprint / Face' : 'Real-time GPS Geofenced Punch'),
            _buildFieldRow('Biometric Machine ID', emp.biometricId ?? 'N/A'),
            _buildFieldRow('Payroll Status', '1 Standard Working Day credit per calendar date'),
          ], isDark),
          const SizedBox(height: 14),
          Consumer(
            builder: (context, ref, _) {
              final faceStatusAsync = ref.watch(faceRegistrationStatusProvider(emp.id));
              final faceStatus = faceStatusAsync.valueOrNull;
              final isRegistered = faceStatus?.isRegistered ?? (emp.isFaceRegistered ?? false);

              return _buildInfoCard('Biometric Face Registration (Admin / HR View)', [
                _buildFieldRow(
                  'Face Biometric Status',
                  isRegistered ? '✓ Registered & Active' : '⚠ Not Registered',
                ),
                if (faceStatus?.registeredAt != null)
                  _buildFieldRow(
                    'Registered Date',
                    DateFormat('dd-MMM-yyyy, hh:mm a').format(faceStatus!.registeredAt!),
                  ),
                if (faceStatus?.modelVersion != null)
                  _buildFieldRow('Biometric Model', faceStatus!.modelVersion!),
                if (faceStatus?.registrationDevice != null)
                  _buildFieldRow('Registered Device', faceStatus!.registrationDevice!),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (isRegistered) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Invalidate Face Biometrics?'),
                              content: Text('Are you sure you want to revoke the active face template for ${emp.name}? The employee will be required to re-register before attendance punch verification.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
                                  child: const Text('Revoke Template', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(faceRegistrationRepositoryProvider).invalidateFaceRegistration(emp.id);
                            ref.invalidate(faceRegistrationStatusProvider(emp.id));
                            ref.invalidate(employeesListProvider);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.absent),
                        label: const Text('Revoke Biometrics', style: TextStyle(color: AppColors.absent, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton.icon(
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
                      icon: Icon(isRegistered ? Icons.refresh_rounded : Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      label: Text(
                        isRegistered ? 'Re-register Face' : 'Register Face for Employee',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ], isDark);
            },
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Personal ---
  Widget _buildPersonalTab(Employee emp, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoCard('Personal Information', [
            _buildFieldRow('Full Legal Name', emp.name),
            _buildFieldRow('Gender', emp.gender.isNotEmpty ? emp.gender : 'Not Specified'),
            _buildFieldRow('Date of Birth', emp.dob != null ? DateFormat('dd-MMM-yyyy').format(emp.dob!) : 'N/A'),
            _buildFieldRow("Father's / Guardian Name", emp.fatherName.isNotEmpty ? emp.fatherName : 'N/A'),
            _buildFieldRow('Personal Email', emp.personalEmail != null && emp.personalEmail!.isNotEmpty ? emp.personalEmail! : 'N/A'),
            _buildFieldRow('PAN Number', emp.pan.isNotEmpty ? emp.pan : 'N/A'),
            _buildFieldRow('UAN Number', emp.uan.isNotEmpty ? emp.uan : 'N/A'),
          ], isDark),
        ],
      ),
    );
  }

  // --- Tab 3: Employment ---
  Widget _buildEmploymentTab(Employee emp, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoCard('Employment Details', [
            _buildFieldRow('Employee ID / Code', '${emp.code} (${emp.id})'),
            _buildFieldRow('Department', emp.department),
            _buildFieldRow('Designation', emp.designation),
            _buildFieldRow('Staff Classification', emp.type.displayName),
            _buildFieldRow('Date of Joining', DateFormat('dd-MMM-yyyy').format(emp.joiningDate)),
            _buildFieldRow('Work Location', emp.workLocation),
            _buildFieldRow('Source of Record', emp.creationSource.displayName),
          ], isDark),
          const SizedBox(height: 14),
          _buildInfoCard('Salary & CTC Package', [
            _buildFieldRow('Monthly Gross / CTC', '₹${emp.monthlyCtc.toStringAsFixed(0)} / mo'),
            _buildFieldRow('Annual CTC', '₹${emp.annualCtc.toStringAsFixed(0)} / yr'),
            _buildFieldRow('Basic Salary (50%)', '₹${(emp.basicSalary ?? emp.monthlyCtc * 0.5).toStringAsFixed(0)} / mo'),
            _buildFieldRow('HRA Allowance (25%)', '₹${(emp.hra ?? emp.monthlyCtc * 0.25).toStringAsFixed(0)} / mo'),
            _buildFieldRow('Special Allowance (25%)', '₹${(emp.specialAllowance ?? emp.monthlyCtc * 0.25).toStringAsFixed(0)} / mo'),
            _buildFieldRow('Payment Mode', emp.paymentMode),
          ], isDark),
          const SizedBox(height: 14),
          _buildInfoCard('Increment & Appraisal Policy', [
            _buildFieldRow('Appraisal Cycle', emp.incrementCycle ?? 'Annual'),
            _buildFieldRow('Standard Increment Rate', '${(emp.incrementPercentage ?? 10.0).toStringAsFixed(1)}% (+₹${(emp.monthlyCtc * ((emp.incrementPercentage ?? 10.0) / 100)).toStringAsFixed(0)}/mo)'),
            _buildFieldRow('Projected Revised CTC', '₹${(emp.monthlyCtc * (1 + ((emp.incrementPercentage ?? 10.0) / 100))).toStringAsFixed(0)} / mo'),
            _buildFieldRow('Next Increment Due Date', emp.nextIncrementDate != null ? DateFormat('dd-MMM-yyyy').format(emp.nextIncrementDate!) : DateFormat('dd-MMM-yyyy').format(emp.joiningDate.add(const Duration(days: 365)))),
            _buildFieldRow('Probation Period', '${emp.probationPeriodMonths ?? 6} Months'),
          ], isDark),
          const SizedBox(height: 14),
          _buildInfoCard('Payroll Statutory Info', [
            _buildFieldRow('EPF Enabled', emp.epfEnabled ? 'Yes' : 'No'),
            _buildFieldRow('ESI Enabled', emp.esiEnabled ? 'Yes' : 'No'),
            _buildFieldRow('Professional Tax Enabled', emp.professionalTaxEnabled ? 'Yes' : 'No'),
            _buildFieldRow('PAN Number', emp.pan.isNotEmpty ? emp.pan : 'N/A'),
            _buildFieldRow('UAN Number', emp.uan.isNotEmpty ? emp.uan : 'N/A'),
          ], isDark),
        ],
      ),
    );
  }

  // --- Tab 4: Contact ---
  Widget _buildContactTab(Employee emp, bool isDark) {
    final accNum = emp.accountNumber;
    final maskedAcc = accNum.length > 4 ? '•••• •••• ${accNum.substring(accNum.length - 4)}' : (accNum.isNotEmpty ? accNum : 'N/A');

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoCard('Contact & Emergency Contacts', [
            _buildFieldRow('Official Email', emp.officialEmail ?? emp.email),
            _buildFieldRow('Mobile Phone', emp.phone),
            _buildFieldRow('Emergency Contact Person', emp.emergencyContactName ?? 'N/A'),
            _buildFieldRow('Emergency Contact Phone', emp.emergencyContactPhone ?? 'N/A'),
            _buildFieldRow('Residential Address', emp.address.isNotEmpty ? emp.address : 'N/A'),
          ], isDark),
          const SizedBox(height: 14),
          _buildInfoCard('Bank Account Details', [
            _buildFieldRow('Bank Name', emp.bankName.isNotEmpty ? emp.bankName : 'N/A'),
            _buildFieldRow('Account Number', maskedAcc),
            _buildFieldRow('IFSC Code', emp.ifsc.isNotEmpty ? emp.ifsc : 'N/A'),
            _buildFieldRow('Account Type', emp.accountType.isNotEmpty ? emp.accountType : 'Savings'),
          ], isDark),
        ],
      ),
    );
  }

  // --- Tab 5: Attendance History ---
  Widget _buildAttendanceTab(Employee emp, bool isDark) {
    final attendanceAsync = ref.watch(dailyAttendanceListProvider);

    return attendanceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (allAttendance) {
        final records = allAttendance.where((a) => a.employeeId == emp.id).toList();

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No attendance punches recorded for this employee yet.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final att = records[index];
            final inTime = att.firstPunch != null ? DateFormat('hh:mm a').format(att.firstPunch!.timestamp) : '--';
            final outTime = att.lastPunch != null ? DateFormat('hh:mm a').format(att.lastPunch!.timestamp) : '--';

            return ListTile(
              dense: true,
              leading: Icon(
                att.sourceType.isBiometric ? Icons.fingerprint_rounded : Icons.gps_fixed_rounded,
                color: att.sourceType.isBiometric ? Colors.indigo : AppColors.primary,
              ),
              title: Text(
                '${DateFormat('dd-MMM-yyyy (EEE)').format(att.date)} · ${att.status.displayName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                'IN: $inTime | OUT: $outTime | Sites: ${att.visitedSiteNames.join(", ")}',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: StatusBadge(status: att.status),
            );
          },
        );
      },
    );
  }

  // --- Tab 6: Sites ---
  Widget _buildSitesTab(Employee emp, bool isDark) {
    final mappingsAsync = ref.watch(mappingsListProvider);
    final sitesAsync = ref.watch(sitesListProvider);

    return mappingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (allMappings) {
        final activeMappings = allMappings.where((m) => m.employeeId == emp.id && m.status.isActive).toList();

        if (activeMappings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No active work sites currently mapped to this employee.', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Map sites from the Employee Site Mapping master.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        final sitesList = sitesAsync.value ?? [];

        return ListView.separated(
          itemCount: activeMappings.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final map = activeMappings[index];
            final site = sitesList.where((s) => s.id == map.siteId).firstOrNull;

            return ListTile(
              leading: const Icon(Icons.business_rounded, color: AppColors.primary),
              title: Text(site?.name ?? map.siteId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text(
                'Mapped since: ${DateFormat('dd-MMM-yyyy').format(map.fromDate)} · Client: ${site?.client ?? "N/A"}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.present.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('ACTIVE', style: TextStyle(color: AppColors.present, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  // --- Tab 7: Mapping History ---
  Widget _buildMappingHistoryTab(Employee emp, bool isDark) {
    final mappingsAsync = ref.watch(mappingsListProvider);
    final sitesAsync = ref.watch(sitesListProvider);

    return mappingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (allMappings) {
        final history = allMappings.where((m) => m.employeeId == emp.id).toList();

        if (history.isEmpty) {
          return const Center(child: Text('No historical site mapping records found.'));
        }

        final sitesList = sitesAsync.value ?? [];

        return ListView.separated(
          itemCount: history.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final item = history[index];
            final site = sitesList.where((s) => s.id == item.siteId).firstOrNull;
            return ListTile(
              dense: true,
              leading: Icon(Icons.history_rounded, color: item.status.isActive ? AppColors.present : Colors.grey),
              title: Text('${site?.name ?? item.siteId} (${item.siteId})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(
                'Assigned: ${DateFormat('dd-MMM-yyyy').format(item.fromDate)} · Status: ${item.status.displayName}',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.status.isActive ? AppColors.present : Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.status.displayName,
                  style: TextStyle(
                    color: item.status.isActive ? AppColors.present : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Tab 8: Audit History ---
  Widget _buildAuditHistoryTab(Employee emp, bool isDark) {
    final auditLogsAsync = ref.watch(auditLogsListProvider);

    return auditLogsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (allLogs) {
        final empLogs = allLogs.where((l) => l.targetEntity == emp.id || l.details.contains(emp.name) || l.details.contains(emp.code)).toList();

        if (empLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fact_check_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No audit events logged for this profile yet.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: empLogs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final log = empLogs[index];
            return ListTile(
              dense: true,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 18),
              ),
              title: Text('${log.action} · ${log.actorName} (${log.actorRole})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.description ?? log.details, style: const TextStyle(fontSize: 11.5)),
                  Text(DateFormat('dd-MMM-yyyy hh:mm a').format(log.timestamp), style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 180, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
