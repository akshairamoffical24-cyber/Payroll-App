import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/geofence_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/aurora_background.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/models/regularization_request.dart';
import '../../../shared/models/site.dart';
import '../../../shared/widgets/animated_gps_radar.dart';
import 'widgets/field_staff_location_card.dart';

class GpsVerificationScreen extends ConsumerStatefulWidget {
  final bool isPunchOut;
  final String employeeId;

  const GpsVerificationScreen({
    super.key,
    this.isPunchOut = false,
    required this.employeeId,
  });

  @override
  ConsumerState<GpsVerificationScreen> createState() => _GpsVerificationScreenState();
}

class _GpsVerificationScreenState extends ConsumerState<GpsVerificationScreen> {
  int _step = 0; // 0: Detecting GPS, 1: GPS Found, 2: Checking Approved Sites, 3: Checking Geofence, 4: Done
  GeofenceEvaluationResult? _result;
  String _selectedPreset = 'CTS Chennai (Inside Geofence 42m)';
  Site? _selectedSiteForMultiMatch;

  @override
  void initState() {
    super.initState();
    _startVerificationProcess();
  }

  Future<void> _startVerificationProcess([Position? explicitPos]) async {
    setState(() {
      _step = 0;
      _result = null;
      _selectedSiteForMultiMatch = null;
    });

    final locationService = ref.read(locationServiceProvider);
    final geofenceService = ref.read(geofenceServiceProvider);

    // Step 0: Detecting GPS & Permissions
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final serviceEnabled = await locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _step = 4;
        _result = const GeofenceEvaluationResult(
          state: GeofenceEvaluationState.gpsDisabled,
          message: 'Please enable location services.',
          isPunchAllowed: false,
        );
      });
      return;
    }

    final hasPermission = await locationService.checkLocationPermission();
    if (!hasPermission) {
      final granted = await locationService.requestLocationPermission();
      if (!granted) {
        setState(() {
          _step = 4;
          _result = const GeofenceEvaluationResult(
            state: GeofenceEvaluationState.permissionDenied,
            message: 'Location permission is required for attendance.',
            isPunchAllowed: false,
          );
        });
        return;
      }
    }

    // Step 1: GPS Acquired
    setState(() => _step = 1);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final pos = explicitPos ??
        LocationService.demoLocations[_selectedPreset] ??
        await locationService.getCurrentLocation();

    if (pos == null) {
      setState(() {
        _step = 4;
        _result = const GeofenceEvaluationResult(
          state: GeofenceEvaluationState.error,
          message: 'Unable to determine your current location.',
          isPunchAllowed: false,
        );
      });
      return;
    }

    // Step 2: Checking Approved Sites Mappings
    setState(() => _step = 2);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final activeSiteIds = await ref
        .read(mappingRepositoryProvider)
        .getActiveSiteIdsForEmployee(widget.employeeId);
    final allSites = await ref.read(siteRepositoryProvider).getAllSites();
    final activeSites = allSites.where((s) => activeSiteIds.contains(s.id)).toList();

    // Step 3: Evaluating Geofence
    setState(() => _step = 3);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final evalResult = geofenceService.evaluateEmployeeLocation(
      currentLat: pos.latitude,
      currentLon: pos.longitude,
      accuracy: pos.accuracy,
      activeMappedSites: activeSites,
    );

    // Audit trail logging for rejected or out-of-range punches
    if (!evalResult.isPunchAllowed) {
      ref.read(auditRepositoryProvider).logAction(
            action: 'GPS_PUNCH_REJECTED',
            actorName: 'Employee ${widget.employeeId}',
            actorRole: 'Field Staff',
            details:
                'Attempted punch (${evalResult.state.name}) at GPS (${evalResult.latitude}, ${evalResult.longitude}). Message: ${evalResult.message}',
            targetEntity: widget.employeeId,
          );

      ref.read(notificationRepositoryProvider).addNotification(
            AppNotification(
              id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
              title: 'Attendance Blocked: ${evalResult.state.name}',
              message: evalResult.message,
              timestamp: DateTime.now(),
              type: NotificationType.error,
              category: NotificationCategory.unmappedLocation,
            ),
          );
    }

    if (!mounted) return;
    setState(() {
      _step = 4;
      _result = evalResult;
      if (evalResult.state == GeofenceEvaluationState.verified) {
        _selectedSiteForMultiMatch = evalResult.matchedSite;
      }
    });
  }

  void _proceedToPunch(Site site, double distanceMeters) {
    context.pushReplacement('/field-punch', extra: {
      'site': site,
      'isPunchOut': widget.isPunchOut,
      'employeeId': widget.employeeId,
      'latitude': _result?.latitude ?? site.latitude,
      'longitude': _result?.longitude ?? site.longitude,
      'accuracy': _result?.accuracy ?? 5.0,
      'distanceMeters': distanceMeters,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPunchOut ? 'GPS Geofence: Punch OUT' : 'GPS Geofence: Punch IN'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // GPS Simulator Location Switcher (For Testing & Validation)
                GlassmorphicContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('GPS Test Preset:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPreset,
                          underline: const SizedBox(),
                          items: LocationService.demoLocations.keys.map((k) {
                            return DropdownMenuItem(
                              value: k,
                              child: Text(k, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPreset = val);
                              _startVerificationProcess(LocationService.demoLocations[val]);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Animated Radar Display
                AnimatedGpsRadar(
                  size: 170,
                  isSuccess: _result?.isPunchAllowed == true,
                  isError: _result != null && !_result!.isPunchAllowed,
                  statusText: _getStatusHeading(),
                  subText: _getStatusSubtitle(),
                ),

                const SizedBox(height: 12),

                // Step Progression Indicator
                _buildStepProgressBar(),

                const SizedBox(height: 12),

                // Result Action / Multi-Site Selection / Error Area
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildMainContentArea(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusHeading() {
    switch (_step) {
      case 0:
        return 'Detecting GPS...';
      case 1:
        return '✓ GPS Found';
      case 2:
        return 'Checking Approved Sites...';
      case 3:
        return 'Checking Geofence...';
      case 4:
        if (_result?.state == GeofenceEvaluationState.verified) {
          return '✓ Site Verified';
        } else if (_result?.state == GeofenceEvaluationState.multipleSitesFound) {
          return 'Multiple Approved Sites';
        } else if (_result?.state == GeofenceEvaluationState.outsideGeofence) {
          return 'Outside Geofence';
        } else if (_result?.state == GeofenceEvaluationState.noMappedSites ||
            _result?.state == GeofenceEvaluationState.unmappedLocation) {
          return 'Location Not Mapped';
        } else if (_result?.state == GeofenceEvaluationState.poorAccuracy) {
          return 'Poor GPS Accuracy';
        } else if (_result?.state == GeofenceEvaluationState.permissionDenied) {
          return 'Permission Denied';
        } else if (_result?.state == GeofenceEvaluationState.gpsDisabled) {
          return 'Location Disabled';
        }
        return 'Verification Failed';
      default:
        return 'Verifying Location...';
    }
  }

  String _getStatusSubtitle() {
    switch (_step) {
      case 0:
        return 'Acquiring satellite signal...';
      case 1:
        return 'Location detected';
      case 2:
        return 'Checking active employee-site mappings...';
      case 3:
        return 'Verifying assigned work site...';
      case 4:
        return _result?.message ?? '';
      default:
        return '';
    }
  }

  Widget _buildStepProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isDone = _step > index;
        final isCurrent = _step == index;

        return Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.present
                    : (isCurrent ? AppColors.primary : Colors.grey.withOpacity(0.3)),
              ),
            ),
            if (index < 3)
              Container(
                width: 24,
                height: 2,
                color: isDone ? AppColors.present : Colors.grey.withOpacity(0.3),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildMainContentArea(bool isDark) {
    if (_step < 4 || _result == null) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final res = _result!;

    // 1. Single Verified Site -> Show FieldStaffLocationCard
    if (res.state == GeofenceEvaluationState.verified && res.matchedSite != null) {
      final site = res.matchedSite!;
      final distance = res.nearbyMatches.isNotEmpty
          ? res.nearbyMatches.first.distanceMeters
          : 42.0;

      return FieldStaffLocationCard(
        latitude: res.latitude ?? site.latitude,
        longitude: res.longitude ?? site.longitude,
        accuracy: res.accuracy ?? 6.0,
        site: site,
        distanceMeters: distance,
        status: res.state,
        isPunchOut: widget.isPunchOut,
        onPunchPressed: () => _proceedToPunch(site, distance),
      );
    }

    // 2. Multiple Approved Sites in Range -> Selectable Cards (Requirement 7)
    if (res.state == GeofenceEvaluationState.multipleSitesFound) {
      return GlassmorphicContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.share_location_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Multiple Approved Sites Detected',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your approved work site to continue attendance punch:',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Selectable Site Cards
            ...res.nearbyMatches.map((match) {
              final isSelected = _selectedSiteForMultiMatch?.id == match.site.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedSiteForMultiMatch = match.site);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.25),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.15),
                          ),
                          child: Icon(
                            Icons.domain_rounded,
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.site.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                              ),
                              if (match.site.client.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  match.site.client,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? AppColors.primary : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: match.site.id,
                          groupValue: _selectedSiteForMultiMatch?.id,
                          onChanged: (val) {
                            setState(() => _selectedSiteForMultiMatch = match.site);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _selectedSiteForMultiMatch == null
                  ? null
                  : () {
                      final match = res.nearbyMatches.firstWhere(
                        (m) => m.site.id == _selectedSiteForMultiMatch!.id,
                      );
                      _proceedToPunch(match.site, match.distanceMeters);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isPunchOut ? AppColors.secondary : AppColors.present,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _selectedSiteForMultiMatch != null
                    ? 'CONTINUE WITH ${_selectedSiteForMultiMatch!.name}'
                    : 'SELECT A SITE ABOVE',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Error / Rejected States (Outside Geofence, Unmapped, Poor Accuracy, Permissions)
    return _buildRejectionCard(res, isDark);
  }

  Widget _buildRejectionCard(GeofenceEvaluationResult res, bool isDark) {
    Color cardColor = AppColors.absent;
    IconData cardIcon = Icons.wrong_location_rounded;
    String errorTitle = 'Attendance Rejected';

    if (res.state == GeofenceEvaluationState.outsideGeofence) {
      cardColor = AppColors.late;
      cardIcon = Icons.location_off_rounded;
      errorTitle = 'Outside Permitted Attendance Area';
    } else if (res.state == GeofenceEvaluationState.poorAccuracy) {
      cardColor = AppColors.leave;
      cardIcon = Icons.gps_not_fixed_rounded;
      errorTitle = 'Poor GPS Accuracy';
    } else if (res.state == GeofenceEvaluationState.permissionDenied) {
      cardColor = AppColors.absent;
      cardIcon = Icons.lock_rounded;
      errorTitle = 'Location Permission Required';
    } else if (res.state == GeofenceEvaluationState.gpsDisabled) {
      cardColor = AppColors.absent;
      cardIcon = Icons.location_disabled_rounded;
      errorTitle = 'Location Services Disabled';
    }

    return GlassmorphicContainer(
      customColor: cardColor,
      opacity: 0.08,
      border: Border.all(color: cardColor.withOpacity(0.35)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(cardIcon, color: cardColor, size: 40),
          const SizedBox(height: 10),
          Text(
            errorTitle,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: cardColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            res.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry Scan'),
                  onPressed: () => _startVerificationProcess(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                  icon: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                  label: const Text('Contact HR/Admin', style: TextStyle(color: Colors.white, fontSize: 12)),
                  onPressed: () => _showReportToHrAdminModal(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportToHrAdminModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedReason = 'Out of Geofence (Client site / External field duty)';
    String punchType = widget.isPunchOut ? 'Missed / Late Punch OUT' : 'Late Punch IN (Delayed Arrival)';
    final remarksController = TextEditingController();
    TimeOfDay inTime = const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay outTime = const TimeOfDay(hour: 18, minute: 30);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Report Remarks to HR & Admin',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Explain what happened and why your punch was delayed or out of range. HR or Admin will review your remarks before attendance is accepted.',
                    style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.3),
                  ),
                  const Divider(height: 24),

                  DropdownButtonFormField<String>(
                    value: punchType,
                    decoration: const InputDecoration(
                      labelText: 'Punch Issue Type',
                      prefixIcon: Icon(Icons.alarm_off_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Late Punch IN (Delayed Arrival)',
                        child: Text('Late Punch IN (Delayed Arrival)'),
                      ),
                      DropdownMenuItem(
                        value: 'Missed / Late Punch OUT',
                        child: Text('Missed / Late Punch OUT'),
                      ),
                      DropdownMenuItem(
                        value: 'Both IN & OUT Regularization',
                        child: Text('Both IN & OUT Regularization'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => punchType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Delay / Out of Range',
                      prefixIcon: Icon(Icons.rule_folder_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Out of Geofence (Client site / External field duty)',
                        child: Text('Out of Geofence (External duty)'),
                      ),
                      DropdownMenuItem(
                        value: 'Late Arrival with Prior Permission',
                        child: Text('Late Arrival with Permission'),
                      ),
                      DropdownMenuItem(
                        value: 'Traffic / Public Transport Delay',
                        child: Text('Traffic / Transport Delay'),
                      ),
                      DropdownMenuItem(
                        value: 'GPS / Mobile Network Issue at Site',
                        child: Text('GPS / Network Glitch'),
                      ),
                      DropdownMenuItem(
                        value: 'Forgot to Punch on Time',
                        child: Text('Forgot to Punch on Time'),
                      ),
                      DropdownMenuItem(
                        value: 'Other Urgent Official Reason',
                        child: Text('Other Official Reason'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: inTime);
                            if (picked != null) setModalState(() => inTime = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Actual In-Time',
                              prefixIcon: Icon(Icons.login_rounded, color: AppColors.present, size: 18),
                            ),
                            child: Text(inTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: outTime);
                            if (picked != null) setModalState(() => outTime = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Actual Out-Time',
                              prefixIcon: Icon(Icons.logout_rounded, color: Color(0xFFF59E0B), size: 18),
                            ),
                            child: Text(outTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      labelText: 'What Happened? Detailed Remarks to HR & Admin *',
                      hintText: 'e.g. Arrived at site; client requested urgent inspection outside premises.',
                      prefixIcon: Icon(Icons.comment_bank_outlined, size: 20),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Submit Remarks for HR/Admin Approval',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    onPressed: () {
                      final remarksText = remarksController.text.trim().isEmpty
                          ? 'Employee reported out-of-range delay ($selectedReason).'
                          : remarksController.text.trim();

                      final inTimeStr = '${inTime.hour.toString().padLeft(2, '0')}:${inTime.minute.toString().padLeft(2, '0')}';
                      final outTimeStr = '${outTime.hour.toString().padLeft(2, '0')}:${outTime.minute.toString().padLeft(2, '0')}';

                      ref.read(regularizationRequestsProvider.notifier).addRequest(
                            RegularizationRequest(
                              id: 'REG-${DateTime.now().millisecondsSinceEpoch}',
                              employeeId: widget.employeeId,
                              employeeCode: widget.employeeId == 'EMP-048' ? 'E048' : widget.employeeId,
                              employeeName: widget.employeeId == 'EMP-048' ? 'Praveen Kumar' : 'Praveen Kumar (Field Staff)',
                              department: 'FINANCE & ACCOUNTS / FIELD',
                              requestType: punchType,
                              reasonCategory: selectedReason,
                              attendanceDate: DateTime.now(),
                              requestedInTime: inTimeStr,
                              requestedOutTime: outTimeStr,
                              remarks: remarksText,
                              appliedAt: DateTime.now(),
                              status: RegularizationStatus.pending,
                            ),
                          );

                      ref.read(auditRepositoryProvider).logAction(
                            action: 'REGULARIZATION_REMARKS_SUBMITTED',
                            actorName: 'Employee ${widget.employeeId}',
                            actorRole: 'Field Staff',
                            details: 'Remarks: $remarksText (In: $inTimeStr, Out: $outTimeStr, Reason: $selectedReason)',
                            targetEntity: widget.employeeId,
                          );

                      ref.read(notificationRepositoryProvider).addNotification(
                            AppNotification(
                              id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
                              title: 'Attendance Regularization Request',
                              message: 'Employee ${widget.employeeId} submitted remarks for $punchType: "$remarksText". Pending HR/Admin approval.',
                              timestamp: DateTime.now(),
                              type: NotificationType.warning,
                              category: NotificationCategory.regularization,
                            ),
                          );

                      Navigator.pop(ctx);

                      showDialog(
                        context: context,
                        builder: (confirmCtx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.mark_email_read_rounded, color: AppColors.present),
                              SizedBox(width: 10),
                              Text('Remarks Sent to HR & Admin'),
                            ],
                          ),
                          content: Text(
                            'Your remarks and timing correction have been forwarded to Sarah Jenkins (HR) and Alexander Wright (Admin).\n\n'
                            '• Requested Timing: $inTimeStr - $outTimeStr\n'
                            '• Category: $selectedReason\n'
                            '• Remarks: "$remarksText"\n\n'
                            'Status: PENDING HR/ADMIN APPROVAL',
                          ),
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              onPressed: () {
                                Navigator.pop(confirmCtx);
                                context.go('/field-dashboard');
                              },
                              child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
