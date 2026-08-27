import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/employee_site_mapping.dart';
import '../../../shared/models/site.dart';
import '../../../shared/widgets/app_header.dart';

class SiteMappingScreen extends ConsumerStatefulWidget {
  const SiteMappingScreen({super.key});

  @override
  ConsumerState<SiteMappingScreen> createState() => _SiteMappingScreenState();
}

class _SiteMappingScreenState extends ConsumerState<SiteMappingScreen> {
  String? _selectedEmployeeId;
  DateTime _fromDate = DateTime(2026, 1, 1);
  DateTime? _toDate = DateTime(2026, 12, 31);
  final Set<String> _selectedSiteIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadEmployeeMappings(String empId) async {
    final activeSites = await ref.read(mappingRepositoryProvider).getActiveSiteIdsForEmployee(empId);
    setState(() {
      _selectedEmployeeId = empId;
      _selectedSiteIds.clear();
      _selectedSiteIds.addAll(activeSites);
    });
  }

  Future<void> _saveMappings() async {
    if (_selectedEmployeeId == null) return;
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider);
      await ref.read(mappingRepositoryProvider).saveEmployeeMappings(
            employeeId: _selectedEmployeeId!,
            siteIds: _selectedSiteIds.toList(),
            fromDate: _fromDate,
            toDate: _toDate,
            actorName: '${user?.name ?? 'HR Manager'} (${user?.role.displayName ?? 'HR'})',
          );

      // Audit log
      await ref.read(auditRepositoryProvider).logAction(
            action: 'EMPLOYEE_SITE_MAPPING_UPDATED',
            actorName: user?.name ?? 'HR Manager',
            actorRole: user?.role.displayName ?? 'HR',
            details: 'Assigned ${_selectedSiteIds.length} approved site locations to Employee $_selectedEmployeeId',
            targetEntity: _selectedEmployeeId,
          );

      ref.invalidate(mappingsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site mappings activated successfully for ${_selectedSiteIds.length} location(s).'),
            backgroundColor: AppColors.present,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mapping: $e'), backgroundColor: AppColors.absent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);
    final sitesAsync = ref.watch(sitesListProvider);
    final mappingsAsync = ref.watch(mappingsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Employee-Site Mapping Master',
            subtitle: 'Assign unlimited approved site locations, validity date ranges & maintain audit history',
            trailing: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save Mappings'),
              onPressed: _isSaving ? null : _saveMappings,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Employee & Validity Period
                  GlassmorphicContainer(
                    padding: Responsive.cardPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Step 1: Select Employee & Mapping Validity Window',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        if (isMobile) ...[
                          employeesAsync.when(
                            data: (employees) {
                              if (employees.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'No employees found. Please onboard or import employees first.',
                                          style: TextStyle(fontSize: 13, color: Colors.amber),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final validVal = employees.any((e) => e.id == _selectedEmployeeId)
                                  ? _selectedEmployeeId
                                  : employees.first.id;
                              return DropdownButtonFormField<String>(
                                value: validVal,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Target Employee',
                                  prefixIcon: Icon(Icons.person_pin_rounded, size: 20),
                                ),
                                items: employees.map((e) {
                                  return DropdownMenuItem(
                                    value: e.id,
                                    child: Text(
                                      '${e.name} (${e.code}) — ${e.designation}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) _loadEmployeeMappings(val);
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Error: $e'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                                  label: Text('From: ${DateFormat('dd MMM yyyy').format(_fromDate)}', style: const TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _fromDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) setState(() => _fromDate = picked);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.event_busy_rounded, size: 16),
                                  label: Text(_toDate != null ? 'To: ${DateFormat('dd MMM yyyy').format(_toDate!)}' : 'To: Perpetual', style: const TextStyle(fontSize: 12)),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _toDate ?? DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) setState(() => _toDate = picked);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              // Employee Dropdown
                              Expanded(
                                flex: 2,
                                child: employeesAsync.when(
                                  data: (employees) {
                                    if (employees.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'No employees found. Please onboard or import employees first.',
                                                style: TextStyle(fontSize: 13, color: Colors.amber),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final validVal = employees.any((e) => e.id == _selectedEmployeeId)
                                        ? _selectedEmployeeId
                                        : employees.first.id;
                                    return DropdownButtonFormField<String>(
                                      value: validVal,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Target Employee',
                                        prefixIcon: Icon(Icons.person_pin_rounded, size: 20),
                                      ),
                                      items: employees.map((e) {
                                        return DropdownMenuItem(
                                          value: e.id,
                                          child: Text(
                                            '${e.name} (${e.code}) — ${e.designation} [${e.type.displayName}]',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) _loadEmployeeMappings(val);
                                      },
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (e, _) => Text('Error: $e'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // From Date Picker
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                                  label: Text('From: ${DateFormat('dd MMM yyyy').format(_fromDate)}'),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _fromDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) setState(() => _fromDate = picked);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // To Date Picker
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.event_busy_rounded, size: 16),
                                  label: Text(_toDate != null ? 'To: ${DateFormat('dd MMM yyyy').format(_toDate!)}' : 'To: Perpetual'),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _toDate ?? DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) setState(() => _toDate = picked);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Step 2: Available Approved Sites (Unlimited Multi-Selection)
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Step 2: Assign Approved Site Perimeters (Unlimited Locations Allowed)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Selected ${_selectedSiteIds.length} site(s) for this employee',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    final allSites = sitesAsync.value ?? [];
                                    setState(() {
                                      _selectedSiteIds.clear();
                                      _selectedSiteIds.addAll(allSites.map((s) => s.id));
                                    });
                                  },
                                  child: const Text('Select All'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => setState(() => _selectedSiteIds.clear()),
                                  child: const Text('Deselect All'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        sitesAsync.when(
                          data: (sites) {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sites.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final site = sites[idx];
                                final isSelected = _selectedSiteIds.contains(site.id);

                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (bool? checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedSiteIds.add(site.id);
                                      } else {
                                        _selectedSiteIds.remove(site.id);
                                      }
                                    });
                                  },
                                  secondary: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.primary.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.15),
                                    child: Icon(
                                      Icons.domain_rounded,
                                      color: isSelected ? AppColors.primary : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        site.name,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          site.code,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${site.client} · ${site.project} · Geofence: ${site.geofenceRadius.toInt()}m · PO: ${site.poNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error: $err')),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Step 3: Historical Audit Trail of Mappings
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mapping Audit History (Non-Destructive Records)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        mappingsAsync.when(
                          data: (mappings) {
                            final empMappings = mappings
                                .where((m) => m.employeeId == _selectedEmployeeId)
                                .toList();

                            if (empMappings.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No historical mappings recorded for this employee.'),
                              );
                            }

                            final sites = sitesAsync.value ?? [];

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: empMappings.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final mapItem = empMappings[idx];
                                final site = sites.firstWhere(
                                  (s) => s.id == mapItem.siteId,
                                  orElse: () => Site(
                                    id: mapItem.siteId,
                                    code: 'SITE-??',
                                    name: 'Site ${mapItem.siteId}',
                                    client: '',
                                    project: '',
                                    address: '',
                                    latitude: 0,
                                    longitude: 0,
                                    geofenceRadius: 100,
                                    poNumber: '',
                                    siteManagerName: '',
                                    siteEngineerName: '',
                                    status: SiteStatus.active,
                                  ),
                                );

                                return ListTile(
                                  leading: Icon(
                                    mapItem.status == MappingStatus.active
                                        ? Icons.verified_rounded
                                        : Icons.cancel_outlined,
                                    color: mapItem.status == MappingStatus.active
                                        ? AppColors.present
                                        : AppColors.absent,
                                  ),
                                  title: Text('${site.name} (${site.code})'),
                                  subtitle: Text(
                                    'Valid: ${DateFormat('dd MMM yyyy').format(mapItem.fromDate)} to ${mapItem.toDate != null ? DateFormat('dd MMM yyyy').format(mapItem.toDate!) : 'Perpetual'} · Created by: ${mapItem.createdBy}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: mapItem.status == MappingStatus.active
                                          ? AppColors.present.withOpacity(0.12)
                                          : AppColors.absent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      mapItem.status.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: mapItem.status == MappingStatus.active
                                            ? AppColors.present
                                            : AppColors.absent,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ],
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
}
