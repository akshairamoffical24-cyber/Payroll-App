import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/widgets/app_header.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'System Notification Center',
            subtitle: 'Real-time alerts, missing punch warnings, and unmapped GPS attempt notifications',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(notificationRepositoryProvider).markAllAsRead();
                    ref.invalidate(notificationsListProvider);
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Mark All Read'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
                  onPressed: () async {
                    await ref.read(notificationRepositoryProvider).clearAll();
                    ref.invalidate(notificationsListProvider);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.white),
                  label: const Text('Clear All', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: Responsive.pagePadding(context),
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(child: Text('No notifications available.'));
                  }

                  return GlassmorphicContainer(
                    padding: Responsive.cardPadding(context),
                    child: ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (ctx, idx) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final notif = notifications[idx];
                        return ListTile(
                          onTap: () {
                            ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                            ref.invalidate(notificationsListProvider);
                          },
                          leading: CircleAvatar(
                            backgroundColor: notif.type == NotificationType.error
                                ? AppColors.absent.withOpacity(0.15)
                                : (notif.type == NotificationType.warning
                                    ? AppColors.late.withOpacity(0.15)
                                    : AppColors.primary.withOpacity(0.15)),
                            child: Icon(
                              notif.type == NotificationType.error
                                  ? Icons.error_outline_rounded
                                  : (notif.type == NotificationType.warning
                                      ? Icons.warning_amber_rounded
                                      : Icons.info_outline_rounded),
                              color: notif.type == NotificationType.error
                                  ? AppColors.absent
                                  : (notif.type == NotificationType.warning
                                      ? AppColors.late
                                      : AppColors.primary),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                notif.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(notif.timestamp),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
