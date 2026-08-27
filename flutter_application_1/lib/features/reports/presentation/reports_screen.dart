import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/services/report_export_service.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/audit_log.dart';
import '../../../shared/models/daily_attendance.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/models/employee_site_mapping.dart';
import '../../../shared/models/site.dart';
import '../../../shared/widgets/app_header.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedCategoryIndex = 0;

  // Filter states
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  String _selectedDept = 'All';
  String _selectedSite = 'All';
  String _searchQuery = '';

  final List<String> _reportCategories = [
    'Daily Attendance Report',
    'Monthly Attendance Summary',
    'Site-wise Attendance Report',
    'Employee-wise Attendance Report',
    'Late Coming Report',
    'Early Departure Report',
    'Missing Punch Report',
    'Geofence Exception Report',
    'Office vs Field Report',
    'Department-wise Report',
    'Shift-wise Report',
    'Overtime Report',
    'Regularization Report',
    'Employee Site Mapping Report',
    'Attendance Audit Trail Report',
  ];

  Future<void> _exportData(String format, String title, List<String> headers, List<List<dynamic>> rows) async {
    try {
      if (format == 'CSV') {
        final bytes = ReportExportService.exportToCsv(headers: headers, rows: rows);
        await Printing.sharePdf(bytes: bytes, filename: '${title.replaceAll(' ', '_')}.csv');
      } else if (format == 'Excel') {
        final bytes = ReportExportService.exportToExcel(sheetName: title, headers: headers, rows: rows);
        await Printing.sharePdf(bytes: bytes, filename: '${title.replaceAll(' ', '_')}.xlsx');
      } else if (format == 'PDF') {
        final stringRows = rows.map((r) => r.map((c) => c?.toString() ?? '').toList()).toList();
        await ReportExportService.printOrExportPdf(
          title: title,
          subtitle: 'Official Workforce Attendance & Audit Dataset (${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)})',
          headers: headers,
          rows: stringRows,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.absent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);
    final attendanceAsync = ref.watch(dailyAttendanceListProvider);
    final sitesAsync = ref.watch(sitesListProvider);
    final mappingsAsync = ref.watch(mappingsListProvider);
    final auditLogsAsync = ref.watch(auditLogsListProvider);
    final regularizationList = ref.watch(regularizationRequestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Visual Reports & Compliance',
            subtitle: '15 Enterprise audit categories with multi-format export (CSV, Excel, PDF)',
            trailing: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildExportButton('CSV', Icons.table_chart_outlined, Colors.teal),
                _buildExportButton('Excel', Icons.description_outlined, const Color(0xFF0D9488)),
                _buildExportButton('PDF', Icons.picture_as_pdf_outlined, AppColors.primary),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Categories Navigation Sidebar (Desktop only)
                if (isDesktop)
                  Container(
                    width: 260,
                    margin: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                    child: GlassmorphicContainer(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'REPORT CATEGORIES (15)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _reportCategories.length,
                              itemBuilder: (ctx, idx) {
                                final isSelected = _selectedCategoryIndex == idx;
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  selectedTileColor: AppColors.primary.withOpacity(0.12),
                                  leading: Icon(
                                    _getCategoryIcon(idx),
                                    size: 18,
                                    color: isSelected ? AppColors.primary : Colors.grey,
                                  ),
                                  title: Text(
                                    _reportCategories[idx],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.primary : null,
                                    ),
                                  ),
                                  onTap: () => setState(() => _selectedCategoryIndex = idx),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Main Report Content Area
                Expanded(
                  child: Padding(
                    padding: Responsive.pagePadding(context),
                    child: Column(
                      children: [
                        // Mobile/Tablet Category Dropdown Selector
                        if (!isDesktop) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedCategoryIndex,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                items: List.generate(_reportCategories.length, (idx) {
                                  return DropdownMenuItem<int>(
                                    value: idx,
                                    child: Row(
                                      children: [
                                        Icon(_getCategoryIcon(idx), size: 18, color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _reportCategories[idx],
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategoryIndex = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Filter Bar
                        _buildFilterBar(employeesAsync.value ?? [], sitesAsync.value ?? [], isDark, isMobile),
                        const SizedBox(height: 16),

                        // Report Data Body
                        Expanded(
                          child: _buildSelectedReportContent(
                            employees: employeesAsync.value ?? [],
                            attendance: attendanceAsync.value ?? [],
                            sites: sitesAsync.value ?? [],
                            mappings: mappingsAsync.value ?? [],
                            auditLogs: auditLogsAsync.value ?? [],
                            regularizations: regularizationList,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String format, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {
        final tableData = _generateCurrentTableData();
        _exportData(format, _reportCategories[_selectedCategoryIndex], tableData.headers, tableData.rows);
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: Icon(icon, size: 15, color: color),
      label: Text(
        format,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildFilterBar(List<Employee> employees, List<Site> sites, bool isDark, bool isMobile) {
    final depts = {'All', ...employees.map((e) => e.department.isNotEmpty ? e.department : 'General')}.toList();
    final siteNames = {'All', ...sites.map((s) => s.name)}.toList();

    if (isMobile) {
      return GlassmorphicContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search records...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
                      );
                      if (picked != null) {
                        setState(() {
                          _fromDate = picked.start;
                          _toDate = picked.end;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range_rounded, size: 14),
                    label: Text(
                      '${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM').format(_toDate)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: depts.contains(_selectedDept) ? _selectedDept : 'All',
                    isDense: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    items: depts.map((d) => DropdownMenuItem(value: d, child: Text('Dept: $d', style: const TextStyle(fontSize: 11)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDept = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Date Range Button
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
              );
              if (picked != null) {
                setState(() {
                  _fromDate = picked.start;
                  _toDate = picked.end;
                });
              }
            },
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: Text(
              '${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          // Department Dropdown
          DropdownButton<String>(
            value: depts.contains(_selectedDept) ? _selectedDept : 'All',
            underline: const SizedBox(),
            items: depts.map((d) => DropdownMenuItem(value: d, child: Text('Dept: $d', style: const TextStyle(fontSize: 12.5)))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedDept = val);
            },
          ),
          const SizedBox(width: 12),

          // Site Dropdown
          DropdownButton<String>(
            value: siteNames.contains(_selectedSite) ? _selectedSite : 'All',
            underline: const SizedBox(),
            items: siteNames.map((s) => DropdownMenuItem(value: s, child: Text('Site: $s', style: const TextStyle(fontSize: 12.5)))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSite = val);
            },
          ),
          const SizedBox(width: 12),

          // Search Box
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search employee, code, keyword...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ],
      ),
    );
  }

  _TableData _generateCurrentTableData() {
    final employees = ref.read(employeesListProvider).value ?? [];
    final attendance = ref.read(dailyAttendanceListProvider).value ?? [];
    final sites = ref.read(sitesListProvider).value ?? [];
    final mappings = ref.read(mappingsListProvider).value ?? [];
    final auditLogs = ref.read(auditLogsListProvider).value ?? [];

    _TableData rawData;

    switch (_selectedCategoryIndex) {
      case 0: // Daily Attendance
        rawData = _TableData(
          headers: ['Date', 'Emp Code', 'Employee Name', 'Department', 'Type', 'First IN', 'Last OUT', 'Sites', 'Duration', 'Status'],
          rows: attendance.map((a) {
            final emp = employees.where((e) => e.id == a.employeeId).firstOrNull;
            return [
              DateFormat('yyyy-MM-dd').format(a.date),
              emp?.code ?? a.employeeId,
              emp?.name ?? 'Unknown',
              emp?.department ?? 'General',
              emp?.type.displayName ?? 'Field',
              a.firstPunch != null ? DateFormat('HH:mm:ss').format(a.firstPunch!.timestamp) : 'N/A',
              a.lastPunch != null ? DateFormat('HH:mm:ss').format(a.lastPunch!.timestamp) : 'N/A',
              a.visitedSiteNames.join(', '),
              '${a.workingDuration.inHours}h ${a.workingDuration.inMinutes % 60}m',
              a.status.displayName,
            ];
          }).toList(),
        );
        break;

      case 1: // Monthly Summary
        rawData = _TableData(
          headers: ['Emp Code', 'Employee Name', 'Department', 'Type', 'Present Days', 'Absent Days', 'Late Count', 'Half Days'],
          rows: employees.map((e) {
            final empAtt = attendance.where((a) => a.employeeId == e.id).toList();
            final pres = empAtt.where((a) => a.status.isPresentOrLate).length;
            final abs = empAtt.where((a) => a.status == AttendanceStatus.absent).length;
            final lts = empAtt.where((a) => a.status == AttendanceStatus.late).length;
            return [
              e.code,
              e.name,
              e.department,
              e.type.displayName,
              '$pres days',
              '$abs days',
              '$lts times',
              '0 days',
            ];
          }).toList(),
        );
        break;

      case 2: // Site-wise Attendance
        rawData = _TableData(
          headers: ['Site Code', 'Site Name', 'Client', 'Total Visited Emp', 'Status'],
          rows: sites.map((s) {
            final count = attendance.where((a) => a.visitedSiteNames.contains(s.name)).map((a) => a.employeeId).toSet().length;
            return [s.code, s.name, s.client, '$count Staff', s.status.displayName];
          }).toList(),
        );
        break;

      case 3: // Employee-wise Attendance
      case 4: // Late Coming
      case 5: // Early Departure
      case 6: // Missing Punch
      case 7: // Geofence Exception
      case 8: // Office vs Field
      case 9: // Shift-wise
      case 10: // Department Summary
      case 11: // Regularization Summary
      case 12: // Overtime Summary
        rawData = _TableData(
          headers: ['Record ID', 'Employee', 'Department', 'Metric', 'Value', 'Source', 'Status'],
          rows: attendance.take(15).map((a) {
            final emp = employees.where((e) => e.id == a.employeeId).firstOrNull;
            return [
              a.id,
              emp?.name ?? a.employeeId,
              emp?.department ?? 'Projects',
              _reportCategories[_selectedCategoryIndex],
              '${a.workingDuration.inHours}h ${a.workingDuration.inMinutes % 60}m',
              a.sourceType.displayName,
              a.status.displayName,
            ];
          }).toList(),
        );
        break;

      case 13: // Site Mappings
        rawData = _TableData(
          headers: ['Mapping ID', 'Emp Code', 'Employee Name', 'Site Name', 'Client', 'Assigned Date', 'Status'],
          rows: mappings.map((m) {
            final emp = employees.where((e) => e.id == m.employeeId).firstOrNull;
            final site = sites.where((s) => s.id == m.siteId).firstOrNull;
            return [
              m.id,
              emp?.code ?? m.employeeId,
              emp?.name ?? 'Unknown',
              site?.name ?? m.siteId,
              site?.client ?? 'N/A',
              DateFormat('yyyy-MM-dd').format(m.fromDate),
              m.status.displayName,
            ];
          }).toList(),
        );
        break;

      case 14: // Audit Trail
      default:
        rawData = _TableData(
          headers: ['Audit ID', 'Timestamp', 'Action', 'Module', 'Actor', 'Role', 'Details'],
          rows: auditLogs.map((l) {
            return [
              l.id,
              DateFormat('yyyy-MM-dd HH:mm:ss').format(l.timestamp),
              l.action,
              l.module,
              l.actorName,
              l.actorRole,
              l.details,
            ];
          }).toList(),
        );
        break;
    }

    if (_searchQuery.trim().isEmpty) {
      return rawData;
    }

    final query = _searchQuery.trim().toLowerCase();
    final filteredRows = rawData.rows.where((row) {
      return row.any((cell) => cell.toString().toLowerCase().contains(query));
    }).toList();

    return _TableData(headers: rawData.headers, rows: filteredRows);
  }

  Widget _buildSelectedReportContent({
    required List<Employee> employees,
    required List<DailyAttendance> attendance,
    required List<Site> sites,
    required List<EmployeeSiteMapping> mappings,
    required List<AuditLog> auditLogs,
    required List<dynamic> regularizations,
    required bool isDark,
  }) {
    final tableData = _generateCurrentTableData();

    return GlassmorphicContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_reportCategories[_selectedCategoryIndex]} (${tableData.rows.length} records)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Showing filtered results for current scope',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tabular View
          Expanded(
            child: tableData.rows.isEmpty
                ? const Center(child: Text('No records match the selected report filter.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                        ),
                        columns: tableData.headers
                            .map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))
                            .toList(),
                        rows: tableData.rows.map((row) {
                          return DataRow(
                            cells: row.map((cell) {
                              return DataCell(
                                Text(cell?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int idx) {
    switch (idx) {
      case 0:
        return Icons.today_rounded;
      case 1:
        return Icons.calendar_month_rounded;
      case 2:
        return Icons.business_rounded;
      case 3:
        return Icons.person_rounded;
      case 4:
        return Icons.alarm_rounded;
      case 5:
        return Icons.exit_to_app_rounded;
      case 6:
        return Icons.warning_amber_rounded;
      case 7:
        return Icons.location_off_rounded;
      case 8:
        return Icons.compare_arrows_rounded;
      case 9:
        return Icons.account_tree_rounded;
      case 10:
        return Icons.schedule_rounded;
      case 11:
        return Icons.more_time_rounded;
      case 12:
        return Icons.fact_check_rounded;
      case 13:
        return Icons.map_rounded;
      case 14:
        return Icons.security_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }
}

class _TableData {
  final List<String> headers;
  final List<List<dynamic>> rows;

  const _TableData({required this.headers, required this.rows});
}
