import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/widgets/app_header.dart';
import '../../face_registration/data/face_registration_repository.dart';
import '../../face_registration/presentation/face_registration_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'User Profile & Credentials',
            subtitle: 'Manage authentication tokens, assigned role permissions, and personal details',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User Name',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        user?.email ?? 'email@company.com',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          user?.role.displayName.toUpperCase() ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildProfileInfoRow('User ID', user?.id ?? '--'),
                      _buildProfileInfoRow('Employee Reference', user?.employeeId ?? 'N/A (Executive Role)'),
                      _buildProfileInfoRow('Auth Token', '${user?.token?.substring(0, 16)}... (Secure JWT)'),
                      _buildProfileInfoRow('Session Security', 'Role-Guard Protected'),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      if (user?.employeeId != null) ...[
                        Consumer(
                          builder: (context, ref, _) {
                            final faceStatusAsync = ref.watch(faceRegistrationStatusProvider(user!.employeeId!));
                            final faceStatus = faceStatusAsync.valueOrNull;
                            final isRegistered = faceStatus?.isRegistered ?? false;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Biometric Face Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isRegistered ? AppColors.present : Colors.amber).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isRegistered ? '✓ Registered' : '⚠ Not Registered',
                                        style: TextStyle(
                                          color: isRegistered ? AppColors.present : Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => FaceRegistrationScreen(
                                          employeeId: user.employeeId,
                                          employeeName: user.name,
                                          onCompleted: () => ref.invalidate(faceRegistrationStatusProvider(user.employeeId!)),
                                        ),
                                      );
                                    },
                                    icon: Icon(isRegistered ? Icons.refresh_rounded : Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                    label: Text(isRegistered ? 'Re-register Face Biometrics' : 'Register Face Biometrics', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }
}
