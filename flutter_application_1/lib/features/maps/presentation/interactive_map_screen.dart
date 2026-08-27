import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/site.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/site_map_widget.dart';

class InteractiveMapScreen extends ConsumerStatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  Site? _selectedSite;

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(sitesListProvider);
    final mappingsAsync = ref.watch(mappingsListProvider);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Live Site Location & Geofence Map',
            subtitle: 'Visualize all company & client geofence perimeters and assigned employee distribution',
          ),
          Expanded(
            child: sitesAsync.when(
              data: (sites) {
                return Stack(
                  children: [
                    SiteMapWidget(
                      sites: sites,
                      selectedSite: _selectedSite,
                      onSiteSelected: (site) {
                        setState(() => _selectedSite = site);
                        _showSiteDetailsSheet(context, site, mappingsAsync);
                      },
                    ),

                    // Floating Site Selector Overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${sites.length} Active Geofenced Sites',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showSiteDetailsSheet(BuildContext context, Site site, AsyncValue<List<dynamic>> mappingsAsync) {
    final mappings = mappingsAsync.value ?? [];
    final mappedCount = mappings.where((m) => m.siteId == site.id && m.status.isActive).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${site.client} · ${site.project} · Code: ${site.code}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.present.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      site.status.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.present, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildSheetRow('Address', site.address),
              _buildSheetRow('Geofence Radius', '${site.geofenceRadius.toInt()} meters'),
              _buildSheetRow('GPS Coordinates', '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}'),
              _buildSheetRow('PO Number', site.poNumber),
              _buildSheetRow('Site Manager', site.siteManagerName),
              _buildSheetRow('Site Engineer', site.siteEngineerName),
              _buildSheetRow('Mapped Field Staff', '$mappedCount employee(s) mapped'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
