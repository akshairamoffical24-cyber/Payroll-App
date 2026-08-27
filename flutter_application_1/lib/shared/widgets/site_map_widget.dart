import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../models/site.dart';

class SiteMapWidget extends StatelessWidget {
  final List<Site> sites;
  final LatLng? userLocation;
  final Site? selectedSite;
  final Function(Site site)? onSiteSelected;
  final double initialZoom;

  const SiteMapWidget({
    super.key,
    required this.sites,
    this.userLocation,
    this.selectedSite,
    this.onSiteSelected,
    this.initialZoom = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate center point (either user location, selected site, first site, or default Chennai)
    final LatLng center = userLocation ??
        (selectedSite != null
            ? LatLng(selectedSite!.latitude, selectedSite!.longitude)
            : (sites.isNotEmpty
                ? LatLng(sites.first.latitude, sites.first.longitude)
                : const LatLng(12.9716, 80.2442)));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: initialZoom,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              // OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.workpulse.payroll_attendance',
              ),

              // Geofence Circle Overlays
              CircleLayer(
                circles: sites.map((site) {
                  final isSelected = selectedSite?.id == site.id;
                  return CircleMarker(
                    point: LatLng(site.latitude, site.longitude),
                    radius: site.geofenceRadius, // Radius in meters
                    useRadiusInMeter: true,
                    color: isSelected
                        ? const Color(0x453B82F6) // Semi-transparent bright blue
                        : const Color(0x253B82F6),
                    borderColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFF3B82F6),
                    borderStrokeWidth: isSelected ? 3.0 : 2.0,
                  );
                }).toList(),
              ),

              // Site Markers
              MarkerLayer(
                markers: [
                  // Site Pins
                  ...sites.map((site) {
                    final isSelected = selectedSite?.id == site.id;
                    return Marker(
                      point: LatLng(site.latitude, site.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => onSiteSelected?.call(site),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.accentEmerald : AppColors.primary,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.domain_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }),

                  // User Current GPS Beacon Marker
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Map Legend / Badge Overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurface : Colors.white).withOpacity(0.88),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Approved Site & Geofence', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  if (userLocation != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Current GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
