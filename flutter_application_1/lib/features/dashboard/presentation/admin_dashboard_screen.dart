import 'package:fl_chart/fl_chart.dart';
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
import '../../employees/presentation/widgets/excel_import_dialog.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

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
            title: 'Enterprise Attendance Command Center',
            subtitle: 'Real-time workforce monitoring, biometric sync & GPS geofence analytics',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                  label: const Text('Import Excel'),
                  onPressed: () => _openImportDialog(context),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
                  label: const Text('Full Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => context.go('/reports'),
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
                  // KPI Stat Cards Grid
                  _buildStatCardsRow(summary, context),

                  const SizedBox(height: 20),

                  // Data-Driven Dynamic Insights Banner
                  _buildDynamicInsightsBanner(summary, isDark),

                  const SizedBox(height: 20),

                  // Late Punch In / Out Regularization Requests Banner
                  _buildLatePunchApprovalsBanner(context, ref),

                  const SizedBox(height: 24),

                  // Analytics Charts Section (2 Columns)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildAttendanceTrendChart(summary, isDark)),
                                const SizedBox(width: 20),
                                Expanded(flex: 2, child: _buildAttendanceDistributionPie(summary, isDark)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildAttendanceTrendChart(summary, isDark),
                                const SizedBox(height: 20),
                                _buildAttendanceDistributionPie(summary, isDark),
                              ],
                            );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Secondary Charts & Quick Actions Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildDepartmentAttendanceBar(summary, isDark)),
                                const SizedBox(width: 20),
                                Expanded(flex: 2, child: _buildQuickActionsCard(context, isDark)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildDepartmentAttendanceBar(summary, isDark),
                                const SizedBox(height: 20),
                                _buildQuickActionsCard(context, isDark),
                              ],
                            );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Recent Attendance Stream Table
                  _buildRecentAttendanceTable(dailyAttendanceAsync, employeesAsync, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardsRow(AnalyticsSummary summary, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double aspectRatio = 1.6;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
          aspectRatio = 2.4;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
          aspectRatio = 1.8;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: [
            StatCard(
              title: 'Total Workforce',
              value: summary.totalEmployees,
              icon: Icons.people_alt_rounded,
              accentColor: AppColors.primary,
              subtitle: '${summary.officeVsField.officeTotal} Office · ${summary.officeVsField.fieldTotal} Field',
              trendText: summary.activeEmployees > 0 ? '${summary.activeEmployees} Active' : '0 Active',
            ),
            StatCard(
              title: 'Present Today',
              value: summary.presentToday,
              icon: Icons.check_circle_outline_rounded,
              accentColor: AppColors.present,
              subtitle: 'Attended records',
              trendText: '${summary.overallAttendanceRate}% rate',
            ),
            StatCard(
              title: 'Exceptions / Late',
              value: summary.exceptionsTotal,
              icon: Icons.access_time_rounded,
              accentColor: AppColors.late,
              subtitle: '${summary.lateToday} Late · ${summary.missingInToday + summary.missingOutToday} Missing',
              isPositiveTrend: summary.exceptionsTotal == 0,
              trendText: summary.exceptionsTotal > 0 ? 'Action required' : 'All clear',
            ),
            StatCard(
              title: 'Active Sites & Maps',
              value: summary.activeSites,
              icon: Icons.domain_rounded,
              accentColor: AppColors.secondary,
              subtitle: '${summary.activeMappings} Active staff mappings',
              trendText: '${summary.totalSites} Total sites',
            ),
          ],
        );
      },
    );
  }

  Widget _buildDynamicInsightsBanner(AnalyticsSummary summary, bool isDark) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data-Driven Insights & Compliance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 4),
                ...summary.dataDrivenInsights.map((insight) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('• $insight', style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
                    )),
              ],
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
                      child: const Icon(Icons.notification_important_rounded, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending Attendance Regularizations', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.amber)),
                          Text('$pending request(s) awaiting review.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/attendance'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                  child: const Text('Review Requests'),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.notification_important_rounded, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Attendance Regularizations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber)),
                      const SizedBox(height: 2),
                      Text('$pending request(s) awaiting approval or remarks review.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/attendance'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black87),
                  child: const Text('Review Requests'),
                ),
              ],
            ),
    );
  }

  Widget _buildAttendanceTrendChart(AnalyticsSummary summary, bool isDark) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workforce Attendance Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 16),
          if (!summary.hasData)
            const SizedBox(height: 180, child: Center(child: Text('No attendance data available yet.')))
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const labels = ['Present', 'Late', 'Leave', 'Absent'];
                          final idx = val.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Text(labels[idx], style: const TextStyle(fontSize: 11, color: Colors.grey));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: summary.presentToday.toDouble(), color: AppColors.present, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: summary.lateToday.toDouble(), color: AppColors.late, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: summary.leaveToday.toDouble(), color: AppColors.leave, width: 22, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: summary.absentToday.toDouble(), color: AppColors.absent, width: 22, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDistributionPie(AnalyticsSummary summary, bool isDark) {
    final total = (summary.presentToday + summary.lateToday + summary.leaveToday + summary.absentToday);

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const SizedBox(height: 180, child: Center(child: Text('Zero recorded entries.')))
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (summary.presentToday > 0)
                      PieChartSectionData(color: AppColors.present, value: summary.presentToday.toDouble(), title: '${summary.presentToday}', radius: 36, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (summary.lateToday > 0)
                      PieChartSectionData(color: AppColors.late, value: summary.lateToday.toDouble(), title: '${summary.lateToday}', radius: 36, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (summary.leaveToday > 0)
                      PieChartSectionData(color: AppColors.leave, value: summary.leaveToday.toDouble(), title: '${summary.leaveToday}', radius: 36, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (summary.absentToday > 0)
                      PieChartSectionData(color: AppColors.absent, value: summary.absentToday.toDouble(), title: '${summary.absentToday}', radius: 36, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildLegendIndicator('Present (${summary.presentToday})', AppColors.present),
                _buildLegendIndicator('Late (${summary.lateToday})', AppColors.late),
                _buildLegendIndicator('Leave (${summary.leaveToday})', AppColors.leave),
                _buildLegendIndicator('Absent (${summary.absentToday})', AppColors.absent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentAttendanceBar(AnalyticsSummary summary, bool isDark) {
    final depts = summary.departmentMetrics;

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Attendance Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 16),
          if (depts.isEmpty)
            const SizedBox(height: 180, child: Center(child: Text('No department data available.')))
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < depts.length) {
                            final name = depts[idx].department;
                            return Text(name.length > 8 ? name.substring(0, 8) : name, style: const TextStyle(fontSize: 10, color: Colors.grey));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(depts.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: depts[i].attendancePercentage,
                          color: AppColors.primary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, bool isDark) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Onboard Employee',
            icon: Icons.person_add_rounded,
            color: AppColors.primary,
            onTap: () => context.go('/employee-onboarding'),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Import Excel Master',
            icon: Icons.file_upload_rounded,
            color: const Color(0xFF0D9488),
            onTap: () => _openImportDialog(context),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Create Site Location',
            icon: Icons.add_location_alt_rounded,
            color: AppColors.secondary,
            onTap: () => context.go('/sites'),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Employee Site Mapping',
            icon: Icons.hub_rounded,
            color: AppColors.accentEmerald,
            onTap: () => context.go('/site-mapping'),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'Audit Trail Logs',
            icon: Icons.security_rounded,
            color: Colors.indigo,
            onTap: () => context.go('/audit-logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
            Icon(Icons.chevron_right_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentAttendanceTable(
    AsyncValue<List<DailyAttendance>> attendanceAsync,
    AsyncValue<List<Employee>> employeesAsync,
    bool isDark,
  ) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Attendance Stream', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              Text('Real-time punches', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 16),
          attendanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading stream: $err'),
            data: (records) {
              if (records.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No attendance punches recorded yet.')));

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
                    trailing: StatusBadge(status: att.status),
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
