import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/employee.dart';
import '../../../shared/widgets/app_header.dart';
import 'employee_details_popup.dart';
import 'widgets/excel_import_dialog.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _searchQuery = '';
  String _selectedDept = 'All';
  String _selectedType = 'All';
  String _selectedStatus = 'All';

  Future<void> _downloadTemplate() async {
    final service = ref.read(excelImportServiceProvider);
    final bytes = service.generateEmployeeTemplate();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'WorkPulse_Employee_Master_Template.xlsx',
    );
  }

  void _openImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ExcelImportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Employee Directory & Masters',
            subtitle: 'Enterprise workforce master, Excel onboarding, and bi-modal attendance profile settings',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download Template'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/import-history'),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('Import History'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.file_upload_rounded, size: 16),
                  label: const Text('Import Excel', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _openImportDialog,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('+ Add Employee', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => context.go('/onboarding'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Filter & Search Controls Bar
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 800;

                        return Column(
                          children: [
                            Row(
                              children: [
                                // Search Input
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search by employee name, code, email, designation...',
                                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                      isDense: true,
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded, size: 16),
                                              onPressed: () => setState(() => _searchQuery = ''),
                                            )
                                          : null,
                                    ),
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                  ),
                                ),
                                if (!isCompact) ...[
                                  const SizedBox(width: 16),
                                  _buildDepartmentFilter(employeesAsync.value ?? []),
                                  const SizedBox(width: 12),
                                  _buildTypeFilter(),
                                  const SizedBox(width: 12),
                                  _buildStatusFilter(),
                                ],
                              ],
                            ),
                            if (isCompact) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildDepartmentFilter(employeesAsync.value ?? [])),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTypeFilter()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildStatusFilter()),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Employees List Table
                  Expanded(
                    child: employeesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (err, _) => Center(child: Text('Error loading employees: $err')),
                      data: (allEmployees) {
                        final filtered = allEmployees.where((emp) {
                          final matchQuery = _searchQuery.isEmpty ||
                              emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              emp.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              emp.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              emp.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              emp.designation.toLowerCase().contains(_searchQuery.toLowerCase());

                          final matchDept = _selectedDept == 'All' || emp.department == _selectedDept;
                          final matchType = _selectedType == 'All' ||
                              (_selectedType == 'Office' && emp.type.isOffice) ||
                              (_selectedType == 'Field' && emp.type.isField);
                          final matchStatus = _selectedStatus == 'All' ||
                              (_selectedStatus == 'Active' && emp.status.isActive) ||
                              (_selectedStatus == 'Inactive' && !emp.status.isActive);

                          return matchQuery && matchDept && matchType && matchStatus;
                        }).toList();

                        if (allEmployees.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('No employees match the selected filters.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _searchQuery = '';
                                    _selectedDept = 'All';
                                    _selectedType = 'All';
                                    _selectedStatus = 'All';
                                  }),
                                  child: const Text('Reset All Filters'),
                                ),
                              ],
                            ),
                          );
                        }

                        return GlassmorphicContainer(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              itemCount: filtered.length + 1, // +1 for header
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildTableHeader(isDark);
                                }

                                final emp = filtered[index - 1];
                                return _buildEmployeeRow(context, emp, isDark);
                              },
                            ),
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

  Widget _buildDepartmentFilter(List<Employee> employees) {
    final depts = {'All', ...employees.map((e) => e.department.isNotEmpty ? e.department : 'General')}.toList();

    return DropdownButton<String>(
      value: depts.contains(_selectedDept) ? _selectedDept : 'All',
      underline: const SizedBox(),
      items: depts.map((d) => DropdownMenuItem(value: d, child: Text('Dept: $d', style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedDept = val);
      },
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButton<String>(
      value: _selectedType,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('Type: All', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'Office', child: Text('Type: Office (Biometric)', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'Field', child: Text('Type: Field (Mobile GPS)', style: TextStyle(fontSize: 13))),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _selectedType = val);
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButton<String>(
      value: _selectedStatus,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('Status: All', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'Active', child: Text('Status: Active', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'Inactive', child: Text('Status: Inactive', style: TextStyle(fontSize: 13))),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _selectedStatus = val);
      },
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('EMPLOYEE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey))),
          Expanded(flex: 2, child: Text('DEPARTMENT & ROLE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey))),
          Expanded(flex: 2, child: Text('ATTENDANCE SOURCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey))),
          Expanded(flex: 2, child: Text('CONTACT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey))),
          Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey))),
          SizedBox(width: 80, child: Text('ACTION', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(BuildContext context, Employee emp, bool isDark) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => EmployeeDetailsPopup(employeeId: emp.id),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Employee Avatar & Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: emp.type.isOffice ? Colors.blue.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                    child: Text(
                      emp.code.length > 2 ? emp.code.substring(0, 2) : emp.code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: emp.type.isOffice ? Colors.blue : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          '${emp.code} · ${emp.id}',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Department & Role
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emp.department, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  Text(emp.designation, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),

            // Attendance Source Badge
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: emp.type.isOffice ? Colors.indigo.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: emp.type.isOffice ? Colors.indigo.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          emp.type.isOffice ? Icons.fingerprint_rounded : Icons.gps_fixed_rounded,
                          size: 14,
                          color: emp.type.isOffice ? Colors.indigo : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          emp.type.isOffice ? 'Biometric (${emp.biometricId ?? "BIO"})' : 'Mobile GPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: emp.type.isOffice ? Colors.indigo : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contact Details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emp.email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(emp.phone, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),

            // Status Badge
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (emp.status.isActive ? AppColors.present : Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (emp.status.isActive ? AppColors.present : Colors.grey).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  emp.status.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: emp.status.isActive ? AppColors.present : Colors.grey,
                  ),
                ),
              ),
            ),

            // Actions Dropdown
            SizedBox(
              width: 80,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (action) async {
                  if (action == 'view') {
                    showDialog(
                      context: context,
                      builder: (_) => EmployeeDetailsPopup(employeeId: emp.id),
                    );
                  } else if (action == 'toggle') {
                    await ref.read(employeeRepositoryProvider).toggleEmployeeStatus(emp.id);
                    ref.invalidate(employeesListProvider);
                  } else if (action == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Employee'),
                        content: Text('Are you sure you want to delete ${emp.name} (${emp.code})?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(employeeRepositoryProvider).deleteEmployee(emp.id);
                      ref.invalidate(employeesListProvider);
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 8), Text('View Profile')]),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(emp.status.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(emp.status.isActive ? 'Deactivate' : 'Activate'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline_rounded, color: AppColors.absent, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.absent))]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'No employees found.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Get started by importing an Excel roster or onboarding your first employee.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _openImportDialog,
                icon: const Icon(Icons.file_upload_rounded),
                label: const Text('Import Excel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => context.go('/onboarding'),
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                label: const Text('+ Add Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
