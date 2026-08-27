import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/app_notification.dart';

class NotificationDrawer extends ConsumerWidget {
  const NotificationDrawer({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const Align(
        alignment: Alignment.centerRight,
        child: NotificationDrawer(),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 440,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            left: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Real-time geofence & sync alerts',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(notificationRepositoryProvider).clearAll();
                          ref.invalidate(notificationsListProvider);
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.absent),
                        label: const Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.absent,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: AppColors.absent.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: notificationsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text('No alerts at this time', style: TextStyle(color: Colors.grey[500])),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = list[idx];
                      return _buildNotificationCard(context, item, isDark);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading alerts: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification item, bool isDark) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (item.type) {
      case NotificationType.error:
        icon = Icons.error_outline_rounded;
        iconColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFEF4444).withOpacity(0.12);
        break;
      case NotificationType.warning:
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withOpacity(0.12);
        break;
      case NotificationType.success:
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withOpacity(0.12);
        break;
      case NotificationType.info:
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withOpacity(0.12);
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNotificationDetailModal(context, item, isDark),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(item.timestamp),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetailModal(BuildContext context, AppNotification item, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              item.type == NotificationType.error
                  ? Icons.error_rounded
                  : (item.type == NotificationType.warning ? Icons.warning_rounded : Icons.info_rounded),
              color: item.type == NotificationType.error
                  ? const Color(0xFFEF4444)
                  : (item.type == NotificationType.warning ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 6),
            Text(
              '• Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(item.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '• Category: ${item.category.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (item.targetEmployeeId != null)
              Text(
                '• Target Employee: ${item.targetEmployeeId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          if (item.category == NotificationCategory.missingPunch || item.category == NotificationCategory.regularization)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
              icon: const Icon(Icons.approval_rounded, size: 16, color: Colors.white),
              label: const Text('Review in Late Approvals', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                context.go('/regularization-approvals');
              },
            ),
          if (item.category == NotificationCategory.unmappedLocation)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.map_rounded, size: 16, color: Colors.white),
              label: const Text('View On Map', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                context.go('/map');
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
