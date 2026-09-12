import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_providers.dart';
import '../../core/responsive/responsive.dart';
import '../../features/notifications/presentation/notification_drawer.dart';
import '../../shared/models/user.dart';

class AppHeader extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final notificationsAsync = ref.watch(notificationsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalGutter(context),
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withOpacity(0.9)
            : AppColors.lightSurface.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Drawer opener on mobile if inside a scaffold with drawer
          if (isMobile)
            Builder(
              builder: (ctx) {
                final hasDrawer = Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
                if (!hasDrawer) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    tooltip: 'Open navigation',
                  ),
                );
              },
            ),

          // Title & Subtitle
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null && !isMobile)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Trailing widget + Notification Bell + Profile Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (trailing != null)
                if (isMobile)
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: trailing!,
                    ),
                  )
                else
                  trailing!,

              const SizedBox(width: 8),

                // Notification Bell with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        size: isMobile ? 20 : 22,
                      ),
                      onPressed: () => _showNotificationDrawer(context, ref),
                      tooltip: 'Notifications',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.absent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 4),

                // User Profile Avatar (Clickable to edit name)
                Builder(
                  builder: (context) {
                    final rawName = user?.name ?? 'Premkumar';
                    final effectiveName = (rawName.toLowerCase().contains('alexander') || rawName.isEmpty) ? 'Premkumar' : rawName;
                    final initial = effectiveName.isNotEmpty ? effectiveName.substring(0, 1).toUpperCase() : 'P';

                    return Tooltip(
                      message: 'Click to edit profile name',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showEditProfileDialog(context, ref, user),
                          child: isMobile
                              ? CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.primary.withOpacity(0.3),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: AppColors.primary.withOpacity(0.3),
                                        child: Text(
                                          initial,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        effectiveName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showNotificationDrawer(BuildContext context, WidgetRef ref) {
    NotificationDrawer.show(context);
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, User? user) {
    final currentName = user?.name ?? 'Alexander Wright';
    final nameCtrl = TextEditingController(
      text: (currentName.toLowerCase().contains('alexander') || currentName.isEmpty) ? 'Premkumar' : currentName,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final activeName = nameCtrl.text.trim();
            final initialLetter = activeName.isNotEmpty ? activeName.substring(0, 1).toUpperCase() : 'P';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Profile Name',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Update your display name across WorkPulse',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Display Name',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter name (e.g. Premkumar)',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            nameCtrl.clear();
                            setDialogState(() {});
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Quick Set:',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                          label: const Text('Premkumar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          onPressed: () {
                            nameCtrl.text = 'Premkumar';
                            nameCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: nameCtrl.text.length),
                            );
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    if (newName.isNotEmpty) {
                      ref.read(authStateProvider.notifier).updateUserName(newName);
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Display name updated to "$newName" successfully!'),
                          backgroundColor: AppColors.present,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
