import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/regularization_request.dart';
import '../../../shared/widgets/app_header.dart';

class RegularizationApprovalsScreen extends ConsumerStatefulWidget {
  const RegularizationApprovalsScreen({super.key});

  @override
  ConsumerState<RegularizationApprovalsScreen> createState() => _RegularizationApprovalsScreenState();
}

class _RegularizationApprovalsScreenState extends ConsumerState<RegularizationApprovalsScreen> {
  String _selectedFilter = 'Pending';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(regularizationRequestsProvider);
    final user = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = requests.where((r) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'Pending' && r.status.isPending) ||
          (_selectedFilter == 'Approved' && r.status.isApproved) ||
          (_selectedFilter == 'Rejected' && r.status.isRejected);

      final matchesSearch = _searchQuery.isEmpty ||
          r.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.requestType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.remarks.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();

    final pendingCount = requests.where((r) => r.status.isPending).length;
    final approvedCount = requests.where((r) => r.status.isApproved).length;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Late Punch & Regularization Approvals',
            subtitle: 'Review employee remarks for delayed or out-of-range punches before marking attendance',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: pendingCount > 0 ? const Color(0xFFF59E0B).withOpacity(0.15) : AppColors.present.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pendingCount > 0 ? const Color(0xFFF59E0B).withOpacity(0.4) : AppColors.present.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    pendingCount > 0 ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                    size: 18,
                    color: pendingCount > 0 ? const Color(0xFFF59E0B) : AppColors.present,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pendingCount > 0 ? '$pendingCount Pending Review' : 'All Clear',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: pendingCount > 0 ? const Color(0xFFF59E0B) : AppColors.present,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Pending Approvals',
                          count: '$pendingCount',
                          subtitle: 'Requires HR/Admin action',
                          color: const Color(0xFFF59E0B),
                          icon: Icons.pending_actions_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Approved Late Attendance',
                          count: '$approvedCount',
                          subtitle: 'Marked on employee record',
                          color: AppColors.present,
                          icon: Icons.verified_rounded,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Requests',
                          count: '${requests.length}',
                          subtitle: 'This month across sites',
                          color: AppColors.primary,
                          icon: Icons.receipt_long_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filter & Search Bar
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search by employee name, code, department, or remarks...',
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
                              isDense: true,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Wrap(
                          spacing: 8,
                          children: ['Pending', 'Approved', 'Rejected', 'All'].map((tab) {
                            final isSelected = _selectedFilter == tab;
                            return ChoiceChip(
                              label: Text(
                                tab == 'Pending' ? 'Pending ($pendingCount)' : tab,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              onSelected: (_) => setState(() => _selectedFilter = tab),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Request Cards List
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.task_alt_rounded, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No requests found in $_selectedFilter queue',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map((req) => _buildRequestCard(context, req, user?.name ?? 'HR/Admin', isDark)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RegularizationRequest req, String reviewerName, bool isDark) {
    Color statusColor = const Color(0xFFF59E0B);
    if (req.status.isApproved) statusColor = AppColors.present;
    if (req.status.isRejected) statusColor = AppColors.absent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Employee Info & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        req.employeeName.isNotEmpty ? req.employeeName[0].toUpperCase() : 'E',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              req.employeeName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                req.employeeCode,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${req.department} • Applied on ${DateFormat('dd MMM yyyy, hh:mm a').format(req.appliedAt)}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        req.status.isPending
                            ? Icons.hourglass_top_rounded
                            : (req.status.isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        req.status.displayName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Timing & Reason Grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoBlock('Request Type', req.requestType, Icons.category_rounded, isDark),
                ),
                Expanded(
                  child: _buildInfoBlock(
                    'Attendance Date',
                    DateFormat('dd MMM yyyy (EEE)').format(req.attendanceDate),
                    Icons.event_rounded,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildInfoBlock(
                    'Requested Times',
                    '${req.requestedInTime} — ${req.requestedOutTime}',
                    Icons.access_time_filled_rounded,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildInfoBlock('Reason Category', req.reasonCategory, Icons.rule_rounded, isDark),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Employee Remarks Box (What happened)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.25) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.comment_bank_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Employee Remarks (What Happened):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${req.remarks}"',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            if (req.reviewedBy != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.present),
                  const SizedBox(width: 6),
                  Text(
                    'Reviewed by ${req.reviewedBy} on ${DateFormat('dd MMM, hh:mm a').format(req.reviewedAt!)} • ${req.adminReviewRemarks ?? "Late attendance approved"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.present),
                  ),
                ],
              ),
            ],

            // Action Buttons for Pending Requests
            if (req.status.isPending) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.absent,
                      side: const BorderSide(color: AppColors.absent),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject Request'),
                    onPressed: () => _confirmRejectDialog(context, req, reviewerName),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.present,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Approve Late Attendance',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => _confirmApproveDialog(context, req, reviewerName),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  void _confirmApproveDialog(BuildContext context, RegularizationRequest req, String reviewerName) {
    final noteCtrl = TextEditingController(text: 'Approved as per employee remarks & site verification.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.present),
            SizedBox(width: 10),
            Text('Approve Late Attendance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve this request for ${req.employeeName} (${req.employeeCode})?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '• In Time: ${req.requestedInTime}\n• Out Time: ${req.requestedOutTime}\n• Date: ${DateFormat('dd MMM yyyy').format(req.attendanceDate)}',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Approval Remarks (Optional)',
                prefixIcon: Icon(Icons.note_alt_rounded, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.present),
            onPressed: () {
              ref.read(regularizationRequestsProvider.notifier).approveRequest(
                    requestId: req.id,
                    reviewerName: reviewerName,
                    remarks: noteCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Late attendance approved for ${req.employeeName}! Employee dashboard updated.'),
                  backgroundColor: AppColors.present,
                ),
              );
            },
            child: const Text('Confirm & Mark Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRejectDialog(BuildContext context, RegularizationRequest req, String reviewerName) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.absent),
            SizedBox(width: 10),
            Text('Reject Regularization Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject request for ${req.employeeName} (${req.employeeCode}).'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Required) *',
                hintText: 'e.g. Unverified reason / no prior manager consent',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () {
              final reason = reasonCtrl.text.trim().isEmpty ? 'Insufficient justification provided' : reasonCtrl.text.trim();
              ref.read(regularizationRequestsProvider.notifier).rejectRequest(
                    requestId: req.id,
                    reviewerName: reviewerName,
                    reason: reason,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request rejected for ${req.employeeName}.'),
                  backgroundColor: AppColors.absent,
                ),
              );
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
