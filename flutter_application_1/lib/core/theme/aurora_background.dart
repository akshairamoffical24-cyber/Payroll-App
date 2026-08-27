import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;
  final bool showGlows;

  const AuroraBackground({
    super.key,
    required this.child,
    this.showGlows = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Solid/gradient background base
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ),
        ),

        if (showGlows) ...[
          // Top Left Ambient Aurora Blob
          Positioned(
            top: -100,
            left: -100,
            width: 450,
            height: 450,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.primaryDark.withOpacity(0.35),
                          AppColors.secondary.withOpacity(0.15),
                          Colors.transparent,
                        ]
                      : [
                          AppColors.primaryLight.withOpacity(0.25),
                          AppColors.accentCyan.withOpacity(0.12),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // Bottom Right Ambient Aurora Blob
          Positioned(
            bottom: -120,
            right: -100,
            width: 500,
            height: 500,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.secondary.withOpacity(0.3),
                          AppColors.accentTeal.withOpacity(0.15),
                          Colors.transparent,
                        ]
                      : [
                          AppColors.secondary.withOpacity(0.18),
                          AppColors.accentEmerald.withOpacity(0.1),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // Center-Right subtle glow
          Positioned(
            top: 250,
            right: -50,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentCyan.withOpacity(isDark ? 0.12 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],

        // Forefront child
        Positioned.fill(child: child),
      ],
    );
  }
}
