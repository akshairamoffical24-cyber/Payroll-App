import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/audit_log.dart';
import '../../../shared/widgets/app_header.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _searchQuery = '';
  String _selectedModule = 'All';
  String _selectedAction = 'All';

  final List<String> _modules = ['All', 'Employees', 'Sites', 'Mappings', 'Attendance', 'Payroll', 'Security'];
  final List<String> _actions = ['All', 'CREATE', 'UPDATE', 'DELETE', 'MAP', 'IMPORT', 'PUNCH', 'ATTENDANCE_CORRECTED'];

  void _showDiffDialog(BuildContext context, AuditLog log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit Event Details: ${log.id}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    '${log.action} · ${log.actorName} (${log.actorRole}) · ${DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp)}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isMobile ? screenSize.width * 0.95 : 680.0,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description & Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.description ?? log.details, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'Target Record: ${log.entityType ?? "N/A"} (${log.targetEntity ?? log.entityId ?? "N/A"}) · IP: ${log.ipAddress ?? "127.0.0.1"} · Device: ${log.deviceInfo ?? "Client App"}',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Before vs After Diff
                if (log.oldValues != null || log.newValues != null) ...[
                  const Text('Field-Level State Comparison (Diff):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  isMobile
                      ? Column(
                          children: [
                            // Before State
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('BEFORE (Original State):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 8),
                                  Text(
                                    log.oldValues != null ? const JsonEncoder.withIndent('  ').convert(log.oldValues) : 'null (New Record Creation)',
                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // After State
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AFTER (Updated State):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 8),
                                  Text(
                                    log.newValues != null ? const JsonEncoder.withIndent('  ').convert(log.newValues) : 'null (Deleted Record)',
                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Before State
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('BEFORE (Original State):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                    const SizedBox(height: 8),
                                    Text(
                                      log.oldValues != null ? const JsonEncoder.withIndent('  ').convert(log.oldValues) : 'null (New Record Creation)',
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // After State
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('AFTER (Updated State):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 8),
                                    Text(
                                      log.newValues != null ? const JsonEncoder.withIndent('  ').convert(log.newValues) : 'null (Deleted Record)',
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync = ref.watch(auditLogsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Audit Logs & Governance',
            subtitle: 'Immutable system audit trail tracking all master mutations, imports & biometric corrections',
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh Logs'),
              onPressed: () => ref.invalidate(auditLogsListProvider),
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
                                  hintText: 'Search audit logs...',
                                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                                  isDense: true,
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedModule,
                                      isDense: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                      items: _modules.map((m) => DropdownMenuItem(value: m, child: Text('Mod: $m', style: const TextStyle(fontSize: 11)))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedModule = val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedAction,
                                      isDense: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                      items: _actions.map((a) => DropdownMenuItem(value: a, child: Text('Act: $a', style: const TextStyle(fontSize: 11)))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedAction = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Search
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Search audit logs by actor, action, details, entity ID...',
                                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                                    isDense: true,
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Module Filter
                              DropdownButton<String>(
                                value: _selectedModule,
                                underline: const SizedBox(),
                                items: _modules.map((m) => DropdownMenuItem(value: m, child: Text('Module: $m', style: const TextStyle(fontSize: 12.5)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedModule = val);
                                },
                              ),
                              const SizedBox(width: 14),

                              // Action Filter
                              DropdownButton<String>(
                                value: _selectedAction,
                                underline: const SizedBox(),
                                items: _actions.map((a) => DropdownMenuItem(value: a, child: Text('Action: $a', style: const TextStyle(fontSize: 12.5)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedAction = val);
                                },
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Audit Logs Table
                  Expanded(
                    child: auditLogsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading audit logs: $err')),
                      data: (logs) {
                        final filtered = logs.where((l) {
                          final matchQuery = _searchQuery.isEmpty ||
                              l.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              l.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              l.actorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              l.details.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              (l.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                              (l.targetEntity?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

                          final matchModule = _selectedModule == 'All' || l.module.toLowerCase() == _selectedModule.toLowerCase();
                          final matchAction = _selectedAction == 'All' || l.action.toLowerCase() == _selectedAction.toLowerCase();

                          return matchQuery && matchModule && matchAction;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey.withOpacity(0.4)),
                                const SizedBox(height: 14),
                                const Text('No audit log events match the current filter criteria.', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }

                        return GlassmorphicContainer(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final log = filtered[idx];
                                return ListTile(
                                  onTap: () => _showDiffDialog(context, log),
                                  leading: CircleAvatar(
                                    backgroundColor: log.isSuccess ? AppColors.primary.withOpacity(0.12) : AppColors.absent.withOpacity(0.12),
                                    child: Icon(
                                      log.isSuccess ? Icons.security_rounded : Icons.warning_amber_rounded,
                                      color: log.isSuccess ? AppColors.primary : AppColors.absent,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(log.action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('${log.module} · ${log.actorRole}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp),
                                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        log.description ?? log.details,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'By ${log.actorName} · Target: ${log.targetEntity ?? log.entityId ?? "System"} · Click to view before/after diff',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                                );
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
}
