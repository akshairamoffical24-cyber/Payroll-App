import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../models/user.dart';

class AppSidebar extends ConsumerStatefulWidget {
  final String activeRoute;
  final Function(String route) onNavigate;
  final bool isDrawer;

  const AppSidebar({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    this.isDrawer = false,
  });

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollapsed = widget.isDrawer ? false : _isCollapsed;
    final sidebarWidth = widget.isDrawer ? 280.0 : (isCollapsed ? 76.0 : 250.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // App Brand & Logo Header
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          user?.role.displayName ?? 'Enterprise',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.isDrawer)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close menu',
                  )
                else
                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                    tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Nav Items Scrollable List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildNavItem(
                  route: '/dashboard',
                  label: AppStrings.navDashboard,
                  icon: Icons.grid_view_rounded,
                ),
                _buildNavItem(
                  route: '/employees',
                  label: AppStrings.navEmployees,
                  icon: Icons.badge_rounded,
                ),
                _buildNavItem(
                  route: '/onboarding',
                  label: 'Onboarding',
                  icon: Icons.person_add_alt_1_rounded,
                ),
                _buildNavItem(
                  route: '/sites',
                  label: AppStrings.navSites,
                  icon: Icons.domain_rounded,
                ),
                _buildNavItem(
                  route: '/site-mapping',
                  label: AppStrings.navSiteMapping,
                  icon: Icons.hub_rounded,
                ),
                _buildNavItem(
                  route: '/attendance',
                  label: AppStrings.navAttendance,
                  icon: Icons.fact_check_rounded,
                ),
                _buildNavItem(
                  route: '/regularization-approvals',
                  label: 'Late Approvals',
                  icon: Icons.approval_rounded,
                ),
                _buildNavItem(
                  route: '/biometric',
                  label: AppStrings.navBiometric,
                  icon: Icons.fingerprint_rounded,
                ),
                _buildNavItem(
                  route: '/map',
                  label: AppStrings.navMap,
                  icon: Icons.map_rounded,
                ),
                _buildNavItem(
                  route: '/reports',
                  label: AppStrings.navReports,
                  icon: Icons.bar_chart_rounded,
                ),
                _buildNavItem(
                  route: '/payroll',
                  label: AppStrings.navPayroll,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _buildNavItem(
                  route: '/notifications',
                  label: AppStrings.navNotifications,
                  icon: Icons.notifications_active_rounded,
                ),
                if (user?.role == UserRole.admin)
                  _buildNavItem(
                    route: '/audit-logs',
                    label: AppStrings.navAuditLogs,
                    icon: Icons.history_rounded,
                  ),
                _buildNavItem(
                  route: '/settings',
                  label: AppStrings.navSettings,
                  icon: Icons.tune_rounded,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // User Profile & Quick Role Switcher Footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.absent),
                    tooltip: 'Sign Out',
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      widget.onNavigate('/login');
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String route,
    required String label,
    required IconData icon,
  }) {
    final isSelected = widget.activeRoute == route;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCollapsed = widget.isDrawer ? false : _isCollapsed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigate(route),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.primary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
