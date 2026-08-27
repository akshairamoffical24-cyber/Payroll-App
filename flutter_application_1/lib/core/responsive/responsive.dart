import 'package:flutter/material.dart';

/// Supported device categories based on screen width breakpoints.
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Centralized responsive utility and breakpoint system.
///
/// Breakpoints:
/// - Mobile: < 600 px (Small/large phones, portrait)
/// - Tablet: 600 - 1023 px (Tablets, foldables, small browser windows)
/// - Desktop: 1024 - 1439 px (Laptops, standard desktop displays)
/// - Large Desktop: >= 1440 px (Wide & ultra-wide monitors)
class Responsive {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double largeDesktopBreakpoint = 1440.0;

  static const double desktopMaxWidth = 1440.0;
  static const double formMaxWidth = 880.0;
  static const double dialogMaxWidth = 720.0;
  static const double mobileContainerMaxWidth = 480.0;

  /// Returns true if screen width is < 600 px.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Returns true if screen width is between 600 px and 1023 px.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if screen width is 1024 px or wider.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Returns true if screen width is 1440 px or wider.
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= largeDesktopBreakpoint;

  /// Returns true if screen width is < 1024 px.
  static bool isHandheld(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  /// Returns current DeviceType.
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    if (width < largeDesktopBreakpoint) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  /// Returns responsive value of type [T] tailored to device.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
    T? largeDesktop,
  }) {
    final type = deviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop;
    }
  }

  /// Responsive page padding.
  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(18.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Responsive card padding.
  static EdgeInsets cardPadding(BuildContext context) {
    return isMobile(context)
        ? const EdgeInsets.all(12.0)
        : const EdgeInsets.all(18.0);
  }

  /// Responsive dialog padding.
  static EdgeInsets dialogPadding(BuildContext context) {
    return isMobile(context)
        ? const EdgeInsets.all(16.0)
        : const EdgeInsets.all(24.0);
  }

  /// Responsive horizontal gutter.
  static double horizontalGutter(BuildContext context) {
    return isMobile(context) ? 12.0 : 20.0;
  }
}

/// A widget that renders different layouts based on screen size breakpoints.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.largeDesktopBreakpoint && largeDesktop != null) {
          return largeDesktop!;
        } else if (constraints.maxWidth >= Responsive.tabletBreakpoint) {
          return desktop;
        } else if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// A helper builder providing width constraints and device type.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    DeviceType deviceType,
  ) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final DeviceType type;
        if (constraints.maxWidth >= Responsive.largeDesktopBreakpoint) {
          type = DeviceType.largeDesktop;
        } else if (constraints.maxWidth >= Responsive.tabletBreakpoint) {
          type = DeviceType.desktop;
        } else if (constraints.maxWidth >= Responsive.mobileBreakpoint) {
          type = DeviceType.tablet;
        } else {
          type = DeviceType.mobile;
        }
        return builder(context, constraints, type);
      },
    );
  }
}

/// Centers and constrains content to prevent excessive stretching on ultra-wide displays.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = Responsive.desktopMaxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive Row-or-Column widget that automatically displays children
/// in a [Row] on desktop/tablet and in a [Column] on mobile.
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool forceColumnOnTablet;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16.0,
    this.forceColumnOnTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType) {
        final isColumn = deviceType == DeviceType.mobile ||
            (forceColumnOnTablet && deviceType == DeviceType.tablet);

        if (isColumn) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: _withSpacing(children, isHorizontal: false),
          );
        } else {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: _withSpacing(
              children.map((c) => Expanded(child: c)).toList(),
              isHorizontal: true,
            ),
          );
        }
      },
    );
  }

  List<Widget> _withSpacing(List<Widget> items, {required bool isHorizontal}) {
    if (items.isEmpty) return [];
    final spaced = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      spaced.add(items[i]);
      if (i < items.length - 1) {
        spaced.add(
          isHorizontal ? SizedBox(width: spacing) : SizedBox(height: spacing),
        );
      }
    }
    return spaced;
  }
}
