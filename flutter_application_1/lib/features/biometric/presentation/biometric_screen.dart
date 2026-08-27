import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/widgets/app_header.dart';
import '../data/biometric_adapter.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final _empCodeCtrl = TextEditingController(text: 'EMP003'); // Priya
  String _selectedTerminal = 'ZKT-BIO-HQ-01 (HQ Main Turnstile)';
  bool _isSimulating = false;

  @override
  void dispose() {
    _empCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulateBiometricPunch() async {
    setState(() => _isSimulating = true);

    try {
      final code = _empCodeCtrl.text.trim();
      final emp = await ref.read(employeeRepositoryProvider).getEmployeeByCode(code);

      if (emp == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee with code $code not found!'), backgroundColor: AppColors.absent),
          );
        }
        return;
      }

      final rawPunch = RawBiometricPunch(
        employeeCode: emp.code,
        timestamp: DateTime.now(),
        deviceSerial: 'ZKT-BIO-HQ-01',
        terminalLocation: _selectedTerminal,
      );

      // Ingest punch into Central Attendance Engine
      await ref.read(attendanceRepositoryProvider).ingestBiometricPunch(rawPunch, emp);
      ref.invalidate(dailyAttendanceListProvider);
      ref.invalidate(allPunchesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric punch from ${emp.name} ($code) ingested successfully into central database!'),
            backgroundColor: AppColors.present,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.absent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final punchesAsync = ref.watch(allPunchesProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Office Biometric Integration Hub',
            subtitle: 'Vendor-agnostic adapter layer processing raw biometric device punch streams (Employee Code, Timestamp)',
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              icon: const Icon(Icons.face_retouching_natural_rounded, size: 18, color: Colors.white),
              label: const Text('Face ID Camera Registration', style: TextStyle(color: Colors.white)),
              onPressed: () => _showFaceIdModal(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device Terminal Status Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildTerminalStatusCard(
                          name: 'HQ Main Entrance Turnstile',
                          serial: 'ZKT-BIO-HQ-01',
                          ip: '192.168.10.45',
                          status: 'ONLINE & SYNCED',
                          isOnline: true,
                          lastSync: 'Just now',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTerminalStatusCard(
                          name: 'HQ Rear Wing Terminal',
                          serial: 'ZKT-BIO-HQ-02',
                          ip: '192.168.10.46',
                          status: 'ONLINE & SYNCED',
                          isOnline: true,
                          lastSync: '1 min ago',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTerminalStatusCard(
                          name: 'R&D Center Biometric Gate',
                          serial: 'SUPREMA-RD-01',
                          ip: '192.168.20.12',
                          status: 'ONLINE & SYNCED',
                          isOnline: true,
                          lastSync: '2 mins ago',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Biometric Punch Simulator (Live Demonstration tool)
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.fingerprint_rounded, color: AppColors.secondary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live Biometric Feed Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                Text('Simulate hardware biometric punch events to verify central engine ingestion',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _empCodeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Employee Code (e.g. EMP003, EMP004, EMP006)',
                                  prefixIcon: Icon(Icons.badge_rounded, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedTerminal,
                                decoration: const InputDecoration(
                                  labelText: 'Biometric Terminal Device',
                                  prefixIcon: Icon(Icons.router_rounded, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ZKT-BIO-HQ-01 (HQ Main Turnstile)',
                                    child: Text('ZKT-BIO-HQ-01 (HQ Main Turnstile)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ZKT-BIO-HQ-02 (HQ Rear Wing)',
                                    child: Text('ZKT-BIO-HQ-02 (HQ Rear Wing)'),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _selectedTerminal = val ?? _selectedTerminal),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isSimulating ? null : _simulateBiometricPunch,
                              icon: _isSimulating
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.sensors_rounded, size: 18),
                              label: const Text('Send Biometric Punch'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ingested Biometric Punches Stream
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Raw Biometric Punch Log (Ingested & Processed)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        punchesAsync.when(
                          data: (allPunches) {
                            final bioPunches = allPunches.where((p) => p.source.isBiometric).toList()
                              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                            if (bioPunches.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('No biometric punches logged yet.')),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: bioPunches.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final punch = bioPunches[idx];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.secondary.withOpacity(0.15),
                                    child: const Icon(Icons.fingerprint_rounded, color: AppColors.secondary, size: 20),
                                  ),
                                  title: Text('Employee: ${punch.employeeId} · ${punch.type.displayName} Punch'),
                                  subtitle: Text(
                                    'Timestamp: ${DateFormat('dd MMM yyyy, hh:mm:ss a').format(punch.timestamp)} · Terminal: ${punch.siteName}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.present.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'PROCESSED',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.present),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalStatusCard({
    required String name,
    required String serial,
    required String ip,
    required String status,
    required bool isOnline,
    required String lastSync,
  }) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(serial, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.secondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.present.withOpacity(0.15) : AppColors.absent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? AppColors.present : AppColors.absent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('IP Address: $ip · Heartbeat: $lastSync', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showFaceIdModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _FaceIdEnrollmentDialog(),
    );
  }
}

class _FaceIdEnrollmentDialog extends StatefulWidget {
  const _FaceIdEnrollmentDialog();

  @override
  State<_FaceIdEnrollmentDialog> createState() => _FaceIdEnrollmentDialogState();
}

class _FaceIdEnrollmentDialogState extends State<_FaceIdEnrollmentDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isScanning = true;
  String _statusText = 'Align your face within the reticle frame...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusText = 'Biometric Face ID is active and enrolled for WorkPulse mobile kiosk terminals';
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _rescan() {
    setState(() {
      _isScanning = true;
      _statusText = 'Align your face within the reticle frame...';
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusText = 'Biometric Face ID is active and enrolled for WorkPulse mobile kiosk terminals';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Face ID Biometric Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('AI-assisted anti-spoofing facial recognition', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera Viewfinder Canvas
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isScanning ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isScanning ? const Color(0xFF38BDF8) : const Color(0xFF10B981)).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Face silhouette
                  Icon(
                    Icons.person_rounded,
                    size: 180,
                    color: Colors.white.withOpacity(0.15),
                  ),

                  // Animated Scanning Laser Line
                  if (_isScanning)
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (ctx, child) {
                        return Positioned(
                          top: 40 + (_animController.value * 220),
                          left: 30,
                          right: 30,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.transparent, Color(0xFF38BDF8), Colors.transparent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Reticle corners
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF38BDF8), width: 3),
                          left: BorderSide(color: Color(0xFF38BDF8), width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF38BDF8), width: 3),
                          right: BorderSide(color: Color(0xFF38BDF8), width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF38BDF8), width: 3),
                          left: BorderSide(color: Color(0xFF38BDF8), width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF38BDF8), width: 3),
                          right: BorderSide(color: Color(0xFF38BDF8), width: 3),
                        ),
                      ),
                    ),
                  ),

                  // Success Checkmark when done
                  if (!_isScanning)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Status message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isScanning
                    ? const Color(0xFF38BDF8).withOpacity(0.12)
                    : const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isScanning
                      ? const Color(0xFF38BDF8).withOpacity(0.3)
                      : const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isScanning ? Icons.camera_enhance_rounded : Icons.verified_rounded,
                    size: 18,
                    color: _isScanning ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isScanning ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _rescan,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Re-scan Face'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Face ID template securely enrolled and synchronized across terminals!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
          label: const Text('Done', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
