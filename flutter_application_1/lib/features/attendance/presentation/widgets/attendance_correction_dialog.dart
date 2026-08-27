import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/models/daily_attendance.dart';
import '../../../../shared/models/employee.dart';

class AttendanceCorrectionDialog extends ConsumerStatefulWidget {
  final DailyAttendance attendance;
  final Employee employee;

  const AttendanceCorrectionDialog({
    super.key,
    required this.attendance,
    required this.employee,
  });

  static Future<void> show(BuildContext context, DailyAttendance attendance, Employee employee) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AttendanceCorrectionDialog(attendance: attendance, employee: employee),
    );
  }

  @override
  ConsumerState<AttendanceCorrectionDialog> createState() => _AttendanceCorrectionDialogState();
}

class _AttendanceCorrectionDialogState extends ConsumerState<AttendanceCorrectionDialog> {
  late AttendanceStatus _correctedStatus;
  TimeOfDay? _correctedInTime;
  TimeOfDay? _correctedOutTime;
  final _reasonCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _commonReasons = [
    'Biometric hardware terminal offline / network failure',
    'Official client deputation / external project duty',
    'Forgot to punch IN / OUT at terminal',
    'GPS accuracy glitch at approved client boundary',
    'Pre-approved emergency work from home',
    'Special permission granted by manager',
  ];

  @override
  void initState() {
    super.initState();
    _correctedStatus = widget.attendance.status == AttendanceStatus.absent ||
            widget.attendance.status == AttendanceStatus.missingIn ||
            widget.attendance.status == AttendanceStatus.missingOut
        ? AttendanceStatus.present
        : widget.attendance.status;

    if (widget.attendance.firstPunch != null) {
      _correctedInTime = TimeOfDay.fromDateTime(widget.attendance.firstPunch!.timestamp);
    } else {
      _correctedInTime = const TimeOfDay(hour: 9, minute: 0);
    }

    if (widget.attendance.lastPunch != null) {
      _correctedOutTime = TimeOfDay.fromDateTime(widget.attendance.lastPunch!.timestamp);
    } else {
      _correctedOutTime = const TimeOfDay(hour: 18, minute: 0);
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCorrection() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or specify a mandatory correction reason'), backgroundColor: AppColors.absent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final baseDate = widget.attendance.date;
      DateTime? correctedInDateTime;
      DateTime? correctedOutDateTime;

      if (_correctedInTime != null) {
        correctedInDateTime = DateTime(baseDate.year, baseDate.month, baseDate.day, _correctedInTime!.hour, _correctedInTime!.minute);
      }
      if (_correctedOutTime != null) {
        correctedOutDateTime = DateTime(baseDate.year, baseDate.month, baseDate.day, _correctedOutTime!.hour, _correctedOutTime!.minute);
      }

      final currentUser = ref.read(authStateProvider);
      final reviewerName = currentUser?.name ?? 'HR Administrator';
      final reviewerRole = currentUser?.role.displayName ?? 'HR';

      final oldInStr = widget.attendance.firstPunch != null ? DateFormat('hh:mm a').format(widget.attendance.firstPunch!.timestamp) : 'None';
      final oldOutStr = widget.attendance.lastPunch != null ? DateFormat('hh:mm a').format(widget.attendance.lastPunch!.timestamp) : 'None';

      // Perform repository correction
      await ref.read(attendanceRepositoryProvider).correctAttendanceRecord(
            dailyAttendanceId: widget.attendance.id,
            employeeId: widget.employee.id,
            date: widget.attendance.date,
            correctedInTime: correctedInDateTime,
            correctedOutTime: correctedOutDateTime,
            correctedStatus: _correctedStatus,
            reason: reason,
            reviewerName: reviewerName,
            reviewerRole: reviewerRole,
          );

      // Record Audit Trail with Before/After Diff
      await ref.read(auditRepositoryProvider).logAction(
            action: 'ATTENDANCE_CORRECTED',
            userId: currentUser?.id,
            actorName: reviewerName,
            actorRole: reviewerRole,
            module: 'Attendance',
            entityType: 'DailyAttendance',
            entityId: widget.attendance.id,
            description: 'Attendance corrected for ${widget.employee.name} (${widget.employee.code}) on ${DateFormat('dd-MMM-yyyy').format(widget.attendance.date)}',
            details: 'Reason: $reason. Status changed from ${widget.attendance.status.displayName} to ${_correctedStatus.displayName}. IN: $oldInStr -> ${_correctedInTime?.format(context)}, OUT: $oldOutStr -> ${_correctedOutTime?.format(context)}',
            oldValues: {
              'status': widget.attendance.status.name,
              'inTime': oldInStr,
              'outTime': oldOutStr,
            },
            newValues: {
              'status': _correctedStatus.name,
              'inTime': _correctedInTime != null ? '${_correctedInTime!.hour}:${_correctedInTime!.minute}' : null,
              'outTime': _correctedOutTime != null ? '${_correctedOutTime!.hour}:${_correctedOutTime!.minute}' : null,
              'reason': reason,
              'reviewer': '$reviewerName ($reviewerRole)',
            },
            targetEntity: widget.employee.id,
            isSuccess: true,
          );

      ref.invalidate(dailyAttendanceListProvider);
      ref.invalidate(allPunchesProvider);
      ref.invalidate(auditLogsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance record for ${widget.employee.name} corrected successfully!'),
            backgroundColor: AppColors.present,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Correction failed: $e'), backgroundColor: AppColors.absent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd-MMM-yyyy (EEEE)').format(widget.attendance.date);
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Container(
        width: isMobile ? screenSize.width * 0.95 : 600.0,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.88),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_calendar_rounded, color: Colors.amber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Controlled Attendance Correction', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('${widget.employee.name} (${widget.employee.code}) · $dateStr', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Original status display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Recorded Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(widget.attendance.status.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recorded Punches', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          'IN: ${widget.attendance.firstPunch != null ? DateFormat("hh:mm a").format(widget.attendance.firstPunch!.timestamp) : "Missing"} | OUT: ${widget.attendance.lastPunch != null ? DateFormat("hh:mm a").format(widget.attendance.lastPunch!.timestamp) : "Missing"}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Corrected Status Selector
              const Text('Corrected Attendance Status *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 6),
              DropdownButtonFormField<AttendanceStatus>(
                value: _correctedStatus,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: AttendanceStatus.present, child: Text('Present (Full Day)')),
                  DropdownMenuItem(value: AttendanceStatus.late, child: Text('Late (Present with Delayed Arrival)')),
                  DropdownMenuItem(value: AttendanceStatus.leave, child: Text('On Leave (Approved Leave)')),
                  DropdownMenuItem(value: AttendanceStatus.permission, child: Text('Permission (Approved Short Permission)')),
                  DropdownMenuItem(value: AttendanceStatus.absent, child: Text('Absent')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _correctedStatus = val);
                },
              ),
              const SizedBox(height: 12),

              // Time Correction Pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Corrected IN Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _correctedInTime ?? const TimeOfDay(hour: 9, minute: 0),
                            );
                          if (picked != null) setState(() => _correctedInTime = picked);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(_correctedInTime != null ? _correctedInTime!.format(context) : 'Select Time'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Corrected OUT Time', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _correctedOutTime ?? const TimeOfDay(hour: 18, minute: 0),
                          );
                          if (picked != null) setState(() => _correctedOutTime = picked);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(_correctedOutTime != null ? _correctedOutTime!.format(context) : 'Select Time'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mandatory Reason Selection
            const Text('Mandatory Correction Reason *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              hint: const Text('Select a reason template...'),
              decoration: const InputDecoration(isDense: true),
              items: _commonReasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12.5)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _reasonCtrl.text = val);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Or enter specific customized reason details...',
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitCorrection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  label: const Text('Save & Audit Correction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
