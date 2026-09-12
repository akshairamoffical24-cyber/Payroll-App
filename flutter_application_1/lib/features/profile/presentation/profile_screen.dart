import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/app_header.dart';
import '../../face_registration/data/face_registration_repository.dart';
import '../../face_registration/presentation/face_registration_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final rawName = user?.name ?? 'Premkumar';
    final effectiveName = (rawName.toLowerCase().contains('alexander') || rawName.isEmpty) ? 'Premkumar' : rawName;

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
                          effectiveName.isNotEmpty ? effectiveName.substring(0, 1).toUpperCase() : 'P',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            effectiveName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Change name into Premkumar',
                            child: IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                              onPressed: () => _showEditNameDialog(context, ref, user),
                            ),
                          ),
                        ],
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

  void _showEditNameDialog(BuildContext context, WidgetRef ref, User? user) {
    final currentName = user?.name ?? 'Alexander Wright';
    final nameCtrl = TextEditingController(
      text: (currentName.toLowerCase().contains('alexander') || currentName.isEmpty) ? 'Premkumar' : currentName,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final activeName = nameCtrl.text.trim();
            final initialLetter = activeName.isNotEmpty ? activeName.substring(0, 1).toUpperCase() : 'P';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Profile Name',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Update your display name across WorkPulse',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Display Name',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter name (e.g. Premkumar)',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            nameCtrl.clear();
                            setDialogState(() {});
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Quick Set:',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                          label: const Text('Premkumar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          onPressed: () {
                            nameCtrl.text = 'Premkumar';
                            nameCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: nameCtrl.text.length),
                            );
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    if (newName.isNotEmpty) {
                      ref.read(authStateProvider.notifier).updateUserName(newName);
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Display name updated to "$newName" successfully!'),
                          backgroundColor: AppColors.present,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
