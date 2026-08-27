import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glassmorphic_container.dart';
import '../../../shared/models/site.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/site_map_widget.dart';

class SitesScreen extends ConsumerStatefulWidget {
  const SitesScreen({super.key});

  @override
  ConsumerState<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends ConsumerState<SitesScreen> {
  String _searchQuery = '';
  Site? _selectedSiteForMap;

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(sitesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Site Location Master',
            subtitle: 'Configure approved client sites, GPS coordinates & geofence perimeters',
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_rounded, size: 16),
              label: const Text('Create New Site'),
              onPressed: () => _showAddEditSiteDialog(context),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Search and Info Banner
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;
                      return GlassmorphicContainer(
                        padding: const EdgeInsets.all(14),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Search sites...',
                                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                                      isDense: true,
                                    ),
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shield_rounded, color: AppColors.primary, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'HR/Admin Approved Only (No Auto-Creation)',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Search sites by name, code, client, project, or PO number...',
                                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                                        isDense: true,
                                      ),
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.shield_rounded, color: AppColors.primary, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'HR/Admin Approved Only (No Auto-Creation)',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Main Content: Split List & Map Preview
                  Expanded(
                    child: sitesAsync.when(
                      data: (sites) {
                        final filtered = sites.where((s) {
                          return _searchQuery.isEmpty ||
                              s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              s.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              s.client.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              s.project.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              s.poNumber.toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            return isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: GlassmorphicContainer(
                                          padding: const EdgeInsets.all(12),
                                          child: _buildSitesListView(filtered, isDark),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 2,
                                        child: GlassmorphicContainer(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    _selectedSiteForMap != null
                                                        ? 'Geofence: ${_selectedSiteForMap!.name}'
                                                        : 'Site Geofence Map',
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                  ),
                                                  if (_selectedSiteForMap != null)
                                                    Text(
                                                      'Radius: ${_selectedSiteForMap!.geofenceRadius.toInt()}m',
                                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Expanded(
                                                child: SiteMapWidget(
                                                  sites: sites,
                                                  selectedSite: _selectedSiteForMap ?? (sites.isNotEmpty ? sites.first : null),
                                                  onSiteSelected: (site) => setState(() => _selectedSiteForMap = site),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : GlassmorphicContainer(
                                    padding: const EdgeInsets.all(12),
                                    child: _buildSitesListView(filtered, isDark),
                                  );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading sites: $err')),
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

  Widget _buildSitesListView(List<Site> sites, bool isDark) {
    if (sites.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No sites found')));
    }

    return ListView.separated(
      itemCount: sites.length,
      separatorBuilder: (ctx, idx) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final site = sites[idx];
        final isSelected = _selectedSiteForMap?.id == site.id;

        return ListTile(
          onTap: () => setState(() => _selectedSiteForMap = site),
          selected: isSelected,
          selectedTileColor: AppColors.primary.withOpacity(0.08),
          leading: CircleAvatar(
            backgroundColor: site.status.isActive
                ? AppColors.primary.withOpacity(0.15)
                : Colors.grey.withOpacity(0.15),
            child: Icon(
              Icons.domain_rounded,
              color: site.status.isActive ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                site.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  site.code,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondary),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                '${site.client} · ${site.project} · PO: ${site.poNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                'Geofence: ${site.geofenceRadius.toInt()}m · Lat: ${site.latitude.toStringAsFixed(4)}, Lon: ${site.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Site',
                onPressed: () => _showAddEditSiteDialog(context, site),
              ),
              IconButton(
                icon: Icon(
                  site.status.isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                  size: 18,
                  color: site.status.isActive ? AppColors.present : AppColors.absent,
                ),
                tooltip: 'Toggle Status',
                onPressed: () async {
                  await ref.read(siteRepositoryProvider).toggleSiteStatus(site.id);
                  ref.invalidate(sitesListProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.absent),
                tooltip: 'Delete Site',
                onPressed: () => _confirmDeleteSite(context, site),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteSite(BuildContext context, Site site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppColors.absent),
            const SizedBox(width: 8),
            Text('Delete ${site.name}?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${site.name}" (${site.code}) from the approved Site Master?\n\nThis will remove the site from all employee allocation lists.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () async {
              await ref.read(siteRepositoryProvider).deleteSite(site.id);
              ref.invalidate(sitesListProvider);
              if (_selectedSiteForMap?.id == site.id) {
                setState(() => _selectedSiteForMap = null);
              }
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Site "${site.name}" deleted successfully.'), backgroundColor: AppColors.absent),
                );
              }
            },
            child: const Text('Delete Site', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditSiteDialog(BuildContext context, [Site? site]) {
    final codeCtrl = TextEditingController(text: site?.code ?? 'SITE01${DateTime.now().millisecond % 90 + 10}');
    final nameCtrl = TextEditingController(text: site?.name ?? '');
    final clientCtrl = TextEditingController(text: site?.client ?? 'Client ABC');
    final projectCtrl = TextEditingController(text: site?.project ?? 'Project Alpha');
    final addressCtrl = TextEditingController(text: site?.address ?? 'OMR IT Corridor, Chennai');
    final latCtrl = TextEditingController(text: site?.latitude.toString() ?? '12.9010');
    final lonCtrl = TextEditingController(text: site?.longitude.toString() ?? '80.2279');
    final poCtrl = TextEditingController(text: site?.poNumber ?? 'PO-2026-099');
    final mgrCtrl = TextEditingController(text: site?.siteManagerName ?? 'Muruganandham S.');
    final engCtrl = TextEditingController(text: site?.siteEngineerName ?? 'Rajesh Kumar');
    double geofenceRadius = site?.geofenceRadius ?? 200.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(site == null ? 'Create Site Location Master' : 'Edit Site Location'),
              if (site != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.absent, size: 20),
                  tooltip: 'Delete this site',
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDeleteSite(context, site);
                  },
                ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Site Code (e.g. SITE015)')),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Site Name')),
                  const SizedBox(height: 12),
                  TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client')),
                  const SizedBox(height: 12),
                  TextField(controller: projectCtrl, decoration: const InputDecoration(labelText: 'Project')),
                  const SizedBox(height: 12),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Site Address')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<double>(
                    value: [200.0, 500.0, 700.0, 1000.0].contains(geofenceRadius) ? geofenceRadius : 200.0,
                    decoration: const InputDecoration(
                      labelText: 'Geofence Allowed Radius (Max: 1000m)',
                      helperText: 'Admin/HR approved geofence perimeter to accept attendance',
                      prefixIcon: Icon(Icons.radar_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 200.0,
                        child: Text('200m (Strict Perimeter)'),
                      ),
                      DropdownMenuItem(
                        value: 500.0,
                        child: Text('500m (Standard Campus)'),
                      ),
                      DropdownMenuItem(
                        value: 700.0,
                        child: Text('700m (Extended Site)'),
                      ),
                      DropdownMenuItem(
                        value: 1000.0,
                        child: Text('1000m (Max 1 KM)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => geofenceRadius = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: poCtrl, decoration: const InputDecoration(labelText: 'PO Number')),
                  const SizedBox(height: 12),
                  TextField(controller: mgrCtrl, decoration: const InputDecoration(labelText: 'Site Manager')),
                  const SizedBox(height: 12),
                  TextField(controller: engCtrl, decoration: const InputDecoration(labelText: 'Site Engineer')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newSite = Site(
                  id: site?.id ?? 'SITE-${DateTime.now().millisecondsSinceEpoch}',
                  code: codeCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  client: clientCtrl.text.trim(),
                  project: projectCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text.trim()) ?? 12.9010,
                  longitude: double.tryParse(lonCtrl.text.trim()) ?? 80.2279,
                  geofenceRadius: geofenceRadius,
                  poNumber: poCtrl.text.trim(),
                  siteManagerName: mgrCtrl.text.trim(),
                  siteEngineerName: engCtrl.text.trim(),
                  status: site?.status ?? SiteStatus.active,
                );

                if (site == null) {
                  await ref.read(siteRepositoryProvider).addSite(newSite);
                } else {
                  await ref.read(siteRepositoryProvider).updateSite(newSite);
                }

                ref.invalidate(sitesListProvider);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Site'),
            ),
          ],
        ),
      ),
    );
  }
}
