import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/glassmorphic_container.dart';

class StatCard extends StatelessWidget {
  final String title;
  final num value;
  final String? prefix;
  final String? suffix;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final String? trendText;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.prefix,
    this.suffix,
    this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.trendText,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphicContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              String displayed;
              if (value is int) {
                displayed = val.toInt().toString();
              } else {
                displayed = val.toStringAsFixed(1);
              }
              return Text(
                '${prefix ?? ''}$displayed${suffix ?? ''}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (trendText != null) ...[
                Icon(
                  isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 15,
                  color: isPositiveTrend ? AppColors.present : AppColors.absent,
                ),
                const SizedBox(width: 4),
                Text(
                  trendText!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositiveTrend ? AppColors.present : AppColors.absent,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (subtitle != null)
                Expanded(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
