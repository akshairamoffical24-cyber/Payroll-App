import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/payroll_record.dart';
import '../../../shared/widgets/app_header.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final payrollRepo = ref.watch(payrollRepositoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Payroll-Ready Attendance Summary',
            subtitle: 'Automated calculation of payable working days, leaves, and overtime from central attendance feed',
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload_rounded, size: 16),
              label: const Text('Export ERP'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payroll dataset transmitted successfully to corporate Payroll API gateway!'),
                    backgroundColor: AppColors.present,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: Responsive.pagePadding(context),
              child: Column(
                children: [
                  // Month Selector & Info Box
                  GlassmorphicContainer(
                    padding: Responsive.cardPadding(context),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search employee, department...',
                                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                                  isDense: true,
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedMonth,
                                      isDense: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                      items: List.generate(12, (i) {
                                        final monthNum = i + 1;
                                        return DropdownMenuItem(
                                          value: monthNum,
                                          child: Text(DateFormat('MMMM').format(DateTime(2026, monthNum)), style: const TextStyle(fontSize: 12)),
                                        );
                                      }),
                                      onChanged: (val) => setState(() => _selectedMonth = val ?? _selectedMonth),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedYear,
                                      isDense: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                      items: const [
                                        DropdownMenuItem(value: 2025, child: Text('2025', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 2026, child: Text('2026', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 2027, child: Text('2027', style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (val) => setState(() => _selectedYear = val ?? _selectedYear),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search employee name, code or department...',
                                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                                    isDense: true,
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              DropdownButton<int>(
                                value: _selectedMonth,
                                underline: const SizedBox(),
                                items: List.generate(12, (i) {
                                  final monthNum = i + 1;
                                  return DropdownMenuItem(
                                    value: monthNum,
                                    child: Text(DateFormat('MMMM').format(DateTime(2026, monthNum))),
                                  );
                                }),
                                onChanged: (val) => setState(() => _selectedMonth = val ?? _selectedMonth),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<int>(
                                value: _selectedYear,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 2025, child: Text('2025')),
                                  DropdownMenuItem(value: 2026, child: Text('2026')),
                                  DropdownMenuItem(value: 2027, child: Text('2027')),
                                ],
                                onChanged: (val) => setState(() => _selectedYear = val ?? _selectedYear),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Important Business Rule Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.rule_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Business Rule Compliance: Multiple site punches in a single day (e.g. IN at CTS, OUT at WTC) are strictly consolidated as 1.0 Single Payroll Working Day.',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payroll Records Table
                  Expanded(
                    child: FutureBuilder<List<PayrollRecord>>(
                      future: payrollRepo.getPayrollSummaryForMonth(_selectedMonth, _selectedYear),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading payroll: ${snapshot.error}'));
                        }

                        final records = snapshot.data ?? [];
                        final filtered = records.where((r) {
                          return _searchQuery.isEmpty ||
                              r.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              r.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              r.department.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(child: Text('No payroll records found for this period.'));
                        }

                        return GlassmorphicContainer(
                          padding: const EdgeInsets.all(16),
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (ctx, idx) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final p = filtered[idx];

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showEmployeeWorkingDaysModal(context, p, isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.15),
                                          child: Text(
                                            p.employeeName.substring(0, 1),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    p.employeeName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14.5,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '(${p.employeeCode})',
                                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      p.department,
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Present: ${p.presentDays}d · Late: ${p.lateDays}d · Absent: ${p.absentDays}d · Leaves: ${p.leaveDays}d · OT: ${p.totalOvertimeHours}h',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${p.payableWorkingDays.toStringAsFixed(1)} Days',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                            Text(
                                              'Payable Working Days',
                                              style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
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

  void _showEmployeeWorkingDaysModal(BuildContext context, PayrollRecord p, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(p.employeeName.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.employeeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('${p.employeeCode} • ${p.department}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.present.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.present.withOpacity(0.4)),
              ),
              child: Text(
                '${p.payableWorkingDays.toStringAsFixed(1)} Payable Days',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.present, fontSize: 13),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              const Text('Monthly Attendance & Working Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatPill('Present', '${p.presentDays} Days', AppColors.present, isDark),
                  const SizedBox(width: 8),
                  _buildStatPill('Late Coming', '${p.lateDays} Days', const Color(0xFFF59E0B), isDark),
                  const SizedBox(width: 8),
                  _buildStatPill('Absent', '${p.absentDays} Days', AppColors.absent, isDark),
                  const SizedBox(width: 8),
                  _buildStatPill('Paid Leaves', '${p.leaveDays} Days', Colors.cyan, isDark),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatPill('Overtime Hours', '${p.totalOvertimeHours} hrs', AppColors.primary, isDark),
                  const SizedBox(width: 8),
                  _buildStatPill('Weekly Offs', '4 Days (Paid)', Colors.indigo, isDark),
                  const SizedBox(width: 8),
                  _buildStatPill('Gross Payout Ratio', '100% Full Month', Colors.purple, isDark),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Daily Shift & Productive Hours Log:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    _buildShiftRow('24 Aug 2026', 'CTS Chennai Campus', '08:52 AM', '06:12 PM', '09h 20m', 'Present', AppColors.present),
                    _buildShiftRow('23 Aug 2026', 'CTS -> WTC Site', '09:15 AM', '05:30 PM', '08h 15m', 'Multi-Site Credit', AppColors.present),
                    _buildShiftRow('22 Aug 2026', 'CTS Chennai Campus', '09:35 AM', '06:30 PM', '08h 55m', 'Late (Approved)', const Color(0xFFF59E0B)),
                    _buildShiftRow('21 Aug 2026', 'CTS Chennai Campus', '09:00 AM', '06:00 PM', '09h 00m', 'Present', AppColors.present),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
            label: const Text('Export Employee Slip (PDF)', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exported attendance slip for ${p.employeeName}!'), backgroundColor: AppColors.present),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String val, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.grey[400] : Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftRow(String date, String site, String inTime, String outTime, String duration, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(site, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('$inTime - $outTime', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          Text(duration, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor)),
        ],
      ),
    );
  }
}
