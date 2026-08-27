import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/responsive/responsive.dart';
import '../shared/widgets/app_sidebar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const MainShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _getBottomNavIndex(String path) {
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/employees') || path.startsWith('/onboarding')) return 1;
    if (path.startsWith('/attendance')) return 2;
    if (path.startsWith('/reports')) return 3;
    return 4; // More
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    if (isMobile) {
      final selectedNavIndex = _getBottomNavIndex(currentPath);

      return Scaffold(
        key: scaffoldKey,
        drawer: Drawer(
          child: AppSidebar(
            activeRoute: currentPath,
            onNavigate: (route) {
              Navigator.of(context).pop();
              context.go(route);
            },
            isDrawer: true,
          ),
        ),
        body: SafeArea(
          child: child,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedNavIndex > 3 ? 4 : selectedNavIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.go('/employees');
                break;
              case 2:
                context.go('/attendance');
                break;
              case 3:
                context.go('/reports');
                break;
              case 4:
                scaffoldKey.currentState?.openDrawer();
                break;
            }
          },
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt_rounded, color: AppColors.primary),
              label: 'Employees',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_available_outlined),
              selectedIcon: Icon(Icons.event_available_rounded, color: AppColors.primary),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment_rounded, color: AppColors.primary),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded),
              selectedIcon: Icon(Icons.menu_open_rounded, color: AppColors.primary),
              label: 'More',
            ),
          ],
        ),
      );
    }

    // Tablet & Desktop Layout
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            activeRoute: currentPath,
            onNavigate: (route) => context.go(route),
          ),
          Expanded(
            child: SafeArea(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
