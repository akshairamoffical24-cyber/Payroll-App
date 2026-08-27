import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/aurora_background.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/attendance_punch.dart';
import '../../../shared/models/site.dart';

class PunchScreen extends ConsumerStatefulWidget {
  final Site site;
  final bool isPunchOut;
  final String employeeId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distanceMeters;

  const PunchScreen({
    super.key,
    required this.site,
    this.isPunchOut = false,
    required this.employeeId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distanceMeters,
  });

  @override
  ConsumerState<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends ConsumerState<PunchScreen> {
  bool _isSubmitting = false;
  bool _isSuccess = false;

  Future<void> _submitPunch() async {
    setState(() => _isSubmitting = true);

    try {
      final punchType = widget.isPunchOut ? PunchType.outPunch : PunchType.inPunch;

      await ref.read(attendanceRepositoryProvider).recordMobilePunch(
            employeeId: widget.employeeId,
            type: punchType,
            site: widget.site,
            latitude: widget.latitude,
            longitude: widget.longitude,
            accuracy: widget.accuracy,
            distanceMeters: widget.distanceMeters,
          );

      ref.invalidate(dailyAttendanceListProvider);
      ref.invalidate(allPunchesProvider);

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        context.go('/field-dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording punch: $e'), backgroundColor: AppColors.absent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPunchOut ? 'Confirm Punch OUT' : 'Confirm Punch IN'),
        centerTitle: true,
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isSuccess
                ? _buildSuccessView()
                : Column(
                    children: [
                      const Spacer(),

                      // Verification Badge Card
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.present.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.present),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.present, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'SITE GEOFENCE VERIFIED',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.present,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.site.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${widget.site.client} · ${widget.site.project}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 14),

                            _buildDetailRow('Punch Type', widget.isPunchOut ? 'OUT' : 'IN'),
                            _buildDetailRow('Timestamp', DateFormat('hh:mm:ss a').format(now)),
                            _buildDetailRow('Work Location', widget.site.name),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitPunch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isPunchOut ? AppColors.secondary : AppColors.present,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(widget.isPunchOut ? Icons.logout_rounded : Icons.login_rounded),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.isPunchOut ? 'CONFIRM PUNCH OUT' : 'CONFIRM PUNCH IN',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final now = DateTime.now();

    return Center(
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(28),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.present,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.present.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attendance marked successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.present),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isPunchOut ? 'Punch OUT Verified' : 'Punch IN Verified',
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            _buildDetailRow('Site', widget.site.name),
            _buildDetailRow('Time', DateFormat('hh:mm:ss a').format(now)),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => context.go('/field-dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

