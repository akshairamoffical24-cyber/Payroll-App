import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/widgets/app_header.dart';

// Global Theme Mode State Provider for Dark / Light mode toggling
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _workHours = 8;
  int _lateGraceMins = 30;
  double _defaultRadius = 100.0;
  bool _autoSync = true;

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeModeProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Enterprise Application Settings',
            subtitle: 'Configure attendance thresholds, working hours, geofence radius defaults & theme preference',
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save Settings'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('System configuration settings updated successfully.'),
                    backgroundColor: AppColors.present,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Mode Card
                  GlassmorphicContainer(
                    padding: Responsive.cardPadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Interface Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Select between Dark Mode and Light Mode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 16),
                        if (isMobile) ...[
                          OutlinedButton.icon(
                            icon: const Icon(Icons.dark_mode_rounded),
                            label: const Text('Dark Mode (Default)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              backgroundColor: currentTheme == ThemeMode.dark ? AppColors.primary.withOpacity(0.2) : null,
                              side: BorderSide(
                                color: currentTheme == ThemeMode.dark ? AppColors.primary : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            onPressed: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.light_mode_rounded),
                            label: const Text('Light Mode'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              backgroundColor: currentTheme == ThemeMode.light ? AppColors.primary.withOpacity(0.2) : null,
                              side: BorderSide(
                                color: currentTheme == ThemeMode.light ? AppColors.primary : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            onPressed: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.dark_mode_rounded),
                                  label: const Text('Dark Mode (Default)'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: currentTheme == ThemeMode.dark ? AppColors.primary.withOpacity(0.2) : null,
                                    side: BorderSide(
                                      color: currentTheme == ThemeMode.dark ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  onPressed: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.light_mode_rounded),
                                  label: const Text('Light Mode'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: currentTheme == ThemeMode.light ? AppColors.primary.withOpacity(0.2) : null,
                                    side: BorderSide(
                                      color: currentTheme == ThemeMode.light ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  onPressed: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Business Rules & Grace Period Card
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance Rules & Grace Cutoffs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Standard Working Hours / Day: $_workHours Hours', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: _workHours.toDouble(),
                                    min: 6,
                                    max: 12,
                                    divisions: 6,
                                    label: '$_workHours hrs',
                                    onChanged: (v) => setState(() => _workHours = v.toInt()),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Late Arrival Grace Window: $_lateGraceMins Minutes (09:30 AM cutoff)', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: _lateGraceMins.toDouble(),
                                    min: 0,
                                    max: 60,
                                    divisions: 12,
                                    label: '$_lateGraceMins mins',
                                    onChanged: (v) => setState(() => _lateGraceMins = v.toInt()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Geofence & Hardware Sync Card
                  GlassmorphicContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Geofence & Biometric Hardware Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text('Default Geofence Radius for New Sites: ${_defaultRadius.toInt()} meters', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Slider(
                          value: _defaultRadius,
                          min: 50,
                          max: 300,
                          divisions: 10,
                          label: '${_defaultRadius.toInt()}m',
                          onChanged: (v) => setState(() => _defaultRadius = v),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Auto-Sync Offline Punches upon Connectivity Restore', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Prevents punch loss during network drops in remote field locations', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          value: _autoSync,
                          onChanged: (v) => setState(() => _autoSync = v),
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
}
