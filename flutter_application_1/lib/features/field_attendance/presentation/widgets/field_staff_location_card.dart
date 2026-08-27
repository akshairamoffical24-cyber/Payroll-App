import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/theme/glassmorphic_container.dart';
import '../../../../shared/models/site.dart';

/// Reusable Field Staff Location Card displaying coordinates, accuracy, geofence, and status badge.
class FieldStaffLocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double accuracy;
  final Site? site;
  final double? distanceMeters;
  final GeofenceEvaluationState status;
  final String? statusMessage;
  final bool isPunchOut;
  final VoidCallback? onPunchPressed;
  final VoidCallback? onSelectSitePressed;
  final VoidCallback? onRetryPressed;

  const FieldStaffLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.site,
    this.distanceMeters,
    required this.status,
    this.statusMessage,
    this.isPunchOut = false,
    this.onPunchPressed,
    this.onSelectSitePressed,
    this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status == GeofenceEvaluationState.verified && site != null;
    final isMultiple = status == GeofenceEvaluationState.multipleSitesFound;
    final isOutside = status == GeofenceEvaluationState.outsideGeofence;
    final isUnmapped = status == GeofenceEvaluationState.unmappedLocation ||
        status == GeofenceEvaluationState.noMappedSites;
    final isPoorAccuracy = status == GeofenceEvaluationState.poorAccuracy;

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (isVerified) {
      statusColor = AppColors.present;
      statusTitle = 'LOCATION VERIFIED ✓';
      statusIcon = Icons.check_circle_rounded;
    } else if (isMultiple) {
      statusColor = AppColors.primary;
      statusTitle = 'MULTIPLE APPROVED SITES DETECTED';
      statusIcon = Icons.share_location_rounded;
    } else if (isOutside) {
      statusColor = AppColors.late;
      statusTitle = 'OUTSIDE APPROVED GEOFENCE';
      statusIcon = Icons.warning_amber_rounded;
    } else if (isPoorAccuracy) {
      statusColor = AppColors.leave;
      statusTitle = 'POOR GPS ACCURACY';
      statusIcon = Icons.gps_not_fixed_rounded;
    } else if (isUnmapped) {
      statusColor = AppColors.absent;
      statusTitle = 'LOCATION NOT MAPPED';
      statusIcon = Icons.block_rounded;
    } else {
      statusColor = Colors.grey;
      statusTitle = 'EVALUATING LOCATION...';
      statusIcon = Icons.radar_rounded;
    }

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Site Information
          if (site != null) ...[
            Text(
              'Site:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 2),
            Text(
              site!.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${site!.client} · ${site!.project}',
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
          ],

          // Verification Status Row
          _buildMetricRow(
            'Verification Status',
            isVerified ? 'READY FOR ATTENDANCE' : (statusMessage ?? statusTitle),
            valueColor: isVerified ? AppColors.present : statusColor,
            isBold: true,
          ),

          const SizedBox(height: 20),

          // Action Button Area
          if (isVerified)
            ElevatedButton(
              onPressed: onPunchPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPunchOut ? AppColors.secondary : AppColors.present,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPunchOut ? Icons.logout_rounded : Icons.login_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPunchOut ? 'PUNCH OUT' : 'PUNCH IN',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            )
          else if (isMultiple)
            ElevatedButton(
              onPressed: onSelectSitePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'SELECT APPROVED SITE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton(
              onPressed: onRetryPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: statusColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    'RE-SCAN LOCATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
