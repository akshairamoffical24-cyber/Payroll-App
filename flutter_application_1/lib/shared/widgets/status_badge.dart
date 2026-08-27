import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../models/daily_attendance.dart';

class StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isCompact ? 12 : 14,
            color: config.color,
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: config.color,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  _StatusDisplayConfig _getStatusConfig(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const _StatusDisplayConfig(
          color: AppColors.present,
          icon: Icons.check_circle_rounded,
        );
      case AttendanceStatus.late:
        return const _StatusDisplayConfig(
          color: AppColors.late,
          icon: Icons.schedule_rounded,
        );
      case AttendanceStatus.absent:
        return const _StatusDisplayConfig(
          color: AppColors.absent,
          icon: Icons.cancel_rounded,
        );
      case AttendanceStatus.halfDay:
        return const _StatusDisplayConfig(
          color: AppColors.halfDay,
          icon: Icons.timelapse_rounded,
        );
      case AttendanceStatus.leave:
        return const _StatusDisplayConfig(
          color: AppColors.leave,
          icon: Icons.beach_access_rounded,
        );
      case AttendanceStatus.holiday:
        return const _StatusDisplayConfig(
          color: AppColors.holiday,
          icon: Icons.celebration_rounded,
        );
      case AttendanceStatus.weeklyOff:
        return const _StatusDisplayConfig(
          color: AppColors.weeklyOff,
          icon: Icons.weekend_rounded,
        );
      case AttendanceStatus.permission:
        return const _StatusDisplayConfig(
          color: AppColors.permission,
          icon: Icons.assignment_turned_in_rounded,
        );
      case AttendanceStatus.onDuty:
        return const _StatusDisplayConfig(
          color: AppColors.onDuty,
          icon: Icons.work_history_rounded,
        );
      case AttendanceStatus.missingIn:
        return const _StatusDisplayConfig(
          color: AppColors.missingIn,
          icon: Icons.login_rounded,
        );
      case AttendanceStatus.missingOut:
        return const _StatusDisplayConfig(
          color: AppColors.missingOut,
          icon: Icons.logout_rounded,
        );
    }
  }
}

class _StatusDisplayConfig {
  final Color color;
  final IconData icon;

  const _StatusDisplayConfig({required this.color, required this.icon});
}
