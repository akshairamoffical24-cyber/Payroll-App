import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/services/analytics_engine.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../attendance/presentation/widgets/attendance_correction_dialog.dart';
import '../../employees/presentation/widgets/excel_import_dialog.dart';

class HrDashboardScreen extends ConsumerWidget {
  const HrDashboardScreen({super.key});

  void _openImportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ExcelImportDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analyticsSummaryProvider);
    final dailyAttendanceAsync = ref.watch(dailyAttendanceListProvider);
    final employeesAsync = ref.watch(employeesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'HR Workplace',
            subtitle: 'Daily attendance verification, Excel onboarding, site mapping & correction audit',
            trailing: Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Import Excel'),
                  onPressed: () => _openImportDialog(context),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.hub_rounded, size: 16, color: Colors.white),
                  label: const Text('Map Sites', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => context.go('/site-mapping'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Stats
                  _buildSummaryCards(summary),

                  const SizedBox(height: 20),

                  // Data Insights
                  _buildInsightsCard(summary, isDark),

                  const SizedBox(height: 20),

                  // Late Punch Approvals Banner
                  _buildLatePunchApprovalsBanner(context, ref),

                  const SizedBox(height: 20),

                  // Quick Navigation Shortcuts
                  _buildQuickShortcuts(context, isDark),

                  const SizedBox(height: 24),

                  // Exceptions & Attendance Table
                  _buildExceptionsTable(dailyAttendanceAsync, employeesAsync, context, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double aspectRatio = 1.6;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          aspectRatio = 1.3;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          aspectRatio = 1.8;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: aspectRatio,
          children: [
            StatCard(
              title: 'Active Employees',
              value: summary.activeEmployees,
              icon: Icons.people_alt_rounded,
              accentColor: AppColors.primary,
              subtitle: 'of ${summary.totalEmployees} total registered',
            ),
            StatCard(
              title: 'Present Today',
              value: summary.presentToday,
              icon: Icons.check_circle_rounded,
              accentColor: AppColors.present,
              subtitle: '${summary.overallAttendanceRate.toStringAsFixed(1)}% attendance rate',
            ),
            StatCard(
              title: 'Late Arrivals',
              value: summary.lateToday,
              icon: Icons.schedule_rounded,
              accentColor: Colors.amber.shade700,
              subtitle: 'Require attention / review',
            ),
            StatCard(
              title: 'Absent / Unrecorded',
              value: summary.absentToday,
              icon: Icons.cancel_rounded,
              accentColor: AppColors.absent,
              subtitle: '${summary.leaveToday} on approved leave',
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightsCard(AnalyticsSummary summary, bool isDark) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Live Analytical Insights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${summary.officeVsField.officeTotal} Office / ${summary.officeVsField.fieldTotal} Field',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...summary.dataDrivenInsights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatePunchApprovalsBanner(BuildContext context, WidgetRef ref) {
    final reqs = ref.watch(regularizationRequestsProvider);
    final pending = reqs.where((r) => r.status.isPending).length;

    if (pending == 0) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(context);

    return GlassmorphicContainer(
      padding: Responsive.cardPadding(context),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$pending Late Punch Regularization(s)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const Text(
                            'Justifications awaiting HR review.',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/late-punch-requests'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                  child: const Text('Review Requests'),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pending Late Punch Regularization Request(s) Pending',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Employees flagged with late arrival or out-of-geofence punch have submitted justifications.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/late-punch-requests'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                  child: const Text('Review Requests'),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickShortcuts(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final shortcuts = [
          _buildShortcutCard('Onboard Staff', 'Add new employee', Icons.person_add_rounded, AppColors.primary, () => context.go('/employee-onboarding')),
          _buildShortcutCard('Import Excel', 'Batch Excel roster', Icons.file_upload_rounded, const Color(0xFF0D9488), () => _openImportDialog(context)),
          _buildShortcutCard('Site Mapping', 'Assign client locations', Icons.hub_rounded, AppColors.secondary, () => context.go('/site-mapping')),
          _buildShortcutCard('Attendance Reports', '15 Exportable categories', Icons.analytics_rounded, Colors.teal, () => context.go('/reports')),
        ];

        return isMobile
            ? Column(children: shortcuts.map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: s)).toList())
            : Row(children: shortcuts.map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: s))).toList());
      },
    );
  }

  Widget _buildShortcutCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExceptionsTable(
    AsyncValue<List<DailyAttendance>> attendanceAsync,
    AsyncValue<List<Employee>> employeesAsync,
    BuildContext context,
    bool isDark,
  ) {
    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today’s Live Attendance Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: () => context.push('/reports'), child: const Text('View Detailed Report')),
            ],
          ),
          const SizedBox(height: 12),
          attendanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (records) {
              if (records.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No attendance records for today.')));

              final emps = employeesAsync.value ?? [];

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.take(6).length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final att = records[idx];
                  final emp = emps.where((e) => e.id == att.employeeId).firstOrNull;

                  final inTime = att.firstPunch != null ? DateFormat('hh:mm a').format(att.firstPunch!.timestamp) : '--';
                  final outTime = att.lastPunch != null ? DateFormat('hh:mm a').format(att.lastPunch!.timestamp) : '--';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: att.sourceType.isBiometric ? Colors.indigo.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                      child: Icon(att.sourceType.isBiometric ? Icons.fingerprint_rounded : Icons.gps_fixed_rounded, color: att.sourceType.isBiometric ? Colors.indigo : AppColors.primary, size: 18),
                    ),
                    title: Text('${emp?.name ?? att.employeeId} (${emp?.code ?? ""})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('IN: $inTime | OUT: $outTime | Sites: ${att.visitedSiteNames.join(", ")}', style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(status: att.status),
                        const SizedBox(width: 8),
                        if (emp != null)
                          IconButton(
                            icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.amber),
                            tooltip: 'Correct Attendance Record',
                            onPressed: () => AttendanceCorrectionDialog.show(context, att, emp),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
