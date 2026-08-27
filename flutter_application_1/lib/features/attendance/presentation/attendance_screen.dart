import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/status_badge.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _filterDate = DateTime.now();
  String _selectedStatus = 'All';
  String _selectedSource = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(dailyAttendanceListProvider);
    final employeesAsync = ref.watch(employeesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Attendance Monitoring Center',
            subtitle: 'Unified central attendance pipeline combining Office Biometric and Field Mobile GPS punches',
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Sync Feeds'),
              onPressed: () {
                ref.invalidate(dailyAttendanceListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synchronized biometric and field mobile feeds.')),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: Responsive.pagePadding(context),
              child: Column(
                children: [
                  // Filter Bar
                  GlassmorphicContainer(
                    padding: Responsive.cardPadding(context),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search employee, site...',
                                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                                  isDense: true,
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                      label: Text(DateFormat('dd MMM').format(_filterDate), style: const TextStyle(fontSize: 12)),
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _filterDate,
                                          firstDate: DateTime(2025),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) setState(() => _filterDate = picked);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedStatus,
                                      isDense: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                      items: const [
                                        DropdownMenuItem(value: 'All', child: Text('All Status', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'present', child: Text('Present', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'late', child: Text('Late', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'missingIn', child: Text('Miss IN', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'missingOut', child: Text('Miss OUT', style: TextStyle(fontSize: 12))),
                                        DropdownMenuItem(value: 'absent', child: Text('Absent', style: TextStyle(fontSize: 12))),
                                      ],
                                      onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Search Box
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search employee name, code, site...',
                                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                                    isDense: true,
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Date Selector Button
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                label: Text(DateFormat('dd MMM yyyy').format(_filterDate)),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _filterDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) setState(() => _filterDate = picked);
                                },
                              ),
                              const SizedBox(width: 16),

                              // Status Filter
                              DropdownButton<String>(
                                value: _selectedStatus,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'present', child: Text('Present')),
                                  DropdownMenuItem(value: 'late', child: Text('Late')),
                                  DropdownMenuItem(value: 'missingIn', child: Text('Missing IN')),
                                  DropdownMenuItem(value: 'missingOut', child: Text('Missing OUT')),
                                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                                ],
                                onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
                              ),
                              const SizedBox(width: 16),

                              // Source Filter
                              DropdownButton<String>(
                                value: _selectedSource,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Sources')),
                                  DropdownMenuItem(value: 'mobile', child: Text('Field Mobile (GPS)')),
                                  DropdownMenuItem(value: 'biometric', child: Text('Office Biometric')),
                                ],
                                onChanged: (val) => setState(() => _selectedSource = val ?? 'All'),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Attendance List
                  Expanded(
                    child: attendanceAsync.when(
                      data: (records) {
                        final employees = employeesAsync.value ?? [];
                        final filtered = records.where((r) {
                          final emp = employees.where((e) => e.id == r.employeeId).firstOrNull;
                          final matchesSearch = _searchQuery.isEmpty ||
                              (emp?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                              (emp?.code.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                              r.visitedSiteNames.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));

                          final matchesStatus = _selectedStatus == 'All' || r.status.name == _selectedStatus;
                          final matchesSource = _selectedSource == 'All' || r.sourceType.name == _selectedSource;

                          return matchesSearch && matchesStatus && matchesSource;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No attendance records found matching filters.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        }

                        return GlassmorphicContainer(
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (ctx, idx) => const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final record = filtered[idx];
                              final emp = employees.where((e) => e.id == record.employeeId).firstOrNull ??
                                  Employee(
                                    id: record.employeeId,
                                    code: record.employeeId,
                                    name: 'Unknown Employee',
                                    email: '',
                                    phone: '',
                                    department: 'General',
                                    designation: 'Staff',
                                    type: EmployeeType.office,
                                    status: EmployeeStatus.active,
                                    joiningDate: DateTime.now(),
                                  );

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showAttendanceDetailModal(context, record, emp),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: record.sourceType == AttendanceSourceType.mobile
                                                ? const Color(0xFF3B82F6).withOpacity(0.12)
                                                : const Color(0xFF8B5CF6).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            record.sourceType == AttendanceSourceType.mobile
                                                ? Icons.gps_fixed_rounded
                                                : Icons.fingerprint_rounded,
                                            color: record.sourceType == AttendanceSourceType.mobile
                                                ? const Color(0xFF3B82F6)
                                                : const Color(0xFF8B5CF6),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Text(
                                                    emp.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  Text(
                                                    '(${emp.code})',
                                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: record.sourceType == AttendanceSourceType.mobile
                                                          ? const Color(0xFF3B82F6).withOpacity(0.15)
                                                          : const Color(0xFF8B5CF6).withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      record.sourceType.displayName,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: record.sourceType == AttendanceSourceType.mobile
                                                            ? const Color(0xFF3B82F6)
                                                            : const Color(0xFF8B5CF6),
                                                      ),
                                                    ),
                                                  ),
                                                  if (record.visitedSiteNames.length > 1)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'MULTI-SITE',
                                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Date: ${DateFormat('dd MMM yyyy').format(record.date)} · Sites: ${record.visitedSiteNames.join(' ➔ ')}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'IN: ${_formatPunchTime(record.firstPunch)} · OUT: ${_formatPunchTime(record.lastPunch)} · Duration: ${record.workingDuration.inHours}h ${record.workingDuration.inMinutes.remainder(60)}m',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            StatusBadge(status: record.status),
                                            const SizedBox(width: 8),
                                            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[600] : Colors.grey[400]),
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
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
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

  String _formatPunchTime(dynamic punch) {
    if (punch == null) return '--:--';
    return DateFormat('hh:mm a').format(punch.timestamp);
  }

  void _showAttendanceDetailModal(BuildContext context, DailyAttendance record, Employee emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${emp.code} · ${emp.department} · ${DateFormat('EEEE, dd MMMM yyyy').format(record.date)}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  StatusBadge(status: record.status),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Summary Info
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'First Punch (IN)',
                      _formatPunchTime(record.firstPunch),
                      Icons.login_rounded,
                      AppColors.present,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Last Punch (OUT)',
                      _formatPunchTime(record.lastPunch),
                      Icons.logout_rounded,
                      AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Working Duration',
                      '${record.workingDuration.inHours}h ${record.workingDuration.inMinutes.remainder(60)}m',
                      Icons.timer_rounded,
                      AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'Punch Timeline & GPS / Biometric Path',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: record.allPunches.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final punch = record.allPunches[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: punch.type.isIn ? AppColors.present.withOpacity(0.3) : AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (punch.type.isIn ? AppColors.present : AppColors.secondary).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              punch.type.isIn ? Icons.login_rounded : Icons.logout_rounded,
                              color: punch.type.isIn ? AppColors.present : AppColors.secondary,
                              size: 18,
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
                                      '${punch.type.displayName} Punch',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: punch.type.isIn ? AppColors.present : AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('· ${DateFormat('hh:mm:ss a').format(punch.timestamp)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  punch.siteName ?? 'HQ Biometric Terminal',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                if (punch.latitude != null)
                                  Text(
                                    'GPS: ${punch.latitude!.toStringAsFixed(4)}, ${punch.longitude!.toStringAsFixed(4)} (Accuracy: ${punch.accuracy?.toStringAsFixed(1)}m, Distance: ${punch.distanceMeters?.toInt()}m)',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.present.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.present),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (record.remarks != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.remarks!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
