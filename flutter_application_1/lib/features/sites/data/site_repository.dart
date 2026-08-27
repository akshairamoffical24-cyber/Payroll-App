import 'dart:async';
import '../../../shared/models/site.dart';

abstract class SiteRepository {
  Future<List<Site>> getAllSites();
  Future<Site?> getSiteById(String id);
  Future<Site> addSite(Site site);
  Future<Site> updateSite(Site site);
  Future<void> toggleSiteStatus(String id);
  Future<void> deleteSite(String id);
}

class MockSiteRepository implements SiteRepository {
  final List<Site> _sites = [
    const Site(
      id: 'SITE-001',
      code: 'SITE001',
      name: 'CTS Chennai Campus',
      client: 'Cognizant Tech Solutions',
      project: 'Project Sirius OMR',
      address: 'Plot 1/C1, SIPCOT IT Park, Siruseri, Chennai - 603103',
      latitude: 12.9010,
      longitude: 80.2279,
      geofenceRadius: 200.0,
      poNumber: 'PO-2026-CTS-091',
      siteManagerName: 'Muruganandham S.',
      siteEngineerName: 'Rajesh Kumar',
      status: SiteStatus.active,
    ),
    const Site(
      id: 'SITE-002',
      code: 'SITE002',
      name: 'Wipro Chennai SEZ',
      client: 'Wipro Technologies',
      project: 'Project Falcon Phase 2',
      address: 'ELCOT SEZ, Sholinganallur, Chennai - 600119',
      latitude: 12.9035,
      longitude: 80.2295,
      geofenceRadius: 500.0,
      poNumber: 'PO-2026-WIP-104',
      siteManagerName: 'Karthik Narayanan',
      siteEngineerName: 'Suresh Menon',
      status: SiteStatus.active,
    ),
    const Site(
      id: 'SITE-003',
      code: 'SITE003',
      name: 'WTC Chennai Perungudi',
      client: 'Brigade Enterprises',
      project: 'World Trade Center Towers',
      address: '142 Rajiv Gandhi Salai, Perungudi, Chennai - 600096',
      latitude: 12.9698,
      longitude: 80.2442,
      geofenceRadius: 700.0,
      poNumber: 'PO-2026-WTC-440',
      siteManagerName: 'Arvind Swamy',
      siteEngineerName: 'Rajesh Kumar',
      status: SiteStatus.active,
    ),
    const Site(
      id: 'SITE-004',
      code: 'SITE004',
      name: 'Coimbatore IT Park Project',
      client: 'ELCOT Tamil Nadu',
      project: 'TIDEL Park Extension',
      address: 'Vilankurichi Road, Civil Aerodrome Post, Coimbatore - 641014',
      latitude: 11.0168,
      longitude: 76.9558,
      geofenceRadius: 1000.0,
      poNumber: 'PO-2026-CBE-812',
      siteManagerName: 'Gopalakrishnan V.',
      siteEngineerName: 'Rajesh Kumar',
      status: SiteStatus.active,
    ),
    const Site(
      id: 'SITE-005',
      code: 'SITE005',
      name: 'Client ABC Infra Site',
      client: 'ABC Infrastructure Ltd',
      project: 'Metro Line Expansion',
      address: '100 Feet Road, Indiranagar, Bengaluru - 560038',
      latitude: 12.9716,
      longitude: 77.5946,
      geofenceRadius: 200.0,
      poNumber: 'PO-2026-ABC-319',
      siteManagerName: 'Prakash Rao',
      siteEngineerName: 'Vikram Seth',
      status: SiteStatus.active,
    ),
    const Site(
      id: 'SITE-006',
      code: 'SITE006',
      name: 'Cochin SmartCity Project',
      client: 'SmartCity Kochi FZ-LLC',
      project: 'Tech Pavilion 3',
      address: 'Kakkanad, Kochi, Kerala - 682030',
      latitude: 9.9312,
      longitude: 76.2673,
      geofenceRadius: 500.0,
      poNumber: 'PO-2026-COK-055',
      siteManagerName: 'Thomas Kurian',
      siteEngineerName: 'Rajesh Kumar',
      status: SiteStatus.active,
    ),
    const Site(
      id: 'SITE-007',
      code: 'SITE007',
      name: 'Bangalore Tech Park Block 4',
      client: 'Prestige Estates',
      project: 'Prestige Tech Cloud',
      address: 'Navarathna Agrahara, Bengaluru - 562157',
      latitude: 12.9352,
      longitude: 77.6944,
      geofenceRadius: 1000.0,
      poNumber: 'PO-2026-BLR-901',
      siteManagerName: 'Ramesh Reddy',
      siteEngineerName: 'Vikram Seth',
      status: SiteStatus.active,
    ),
  ];

  @override
  Future<List<Site>> getAllSites() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_sites);
  }

  @override
  Future<Site?> getSiteById(String id) async {
    try {
      return _sites.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Site> addSite(Site site) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sites.insert(0, site);
    return site;
  }

  @override
  Future<Site> updateSite(Site site) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _sites.indexWhere((s) => s.id == site.id);
    if (index != -1) {
      _sites[index] = site;
    }
    return site;
  }

  @override
  Future<void> toggleSiteStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _sites.indexWhere((s) => s.id == id);
    if (index != -1) {
      final current = _sites[index];
      _sites[index] = current.copyWith(
        status: current.status == SiteStatus.active
            ? SiteStatus.inactive
            : SiteStatus.active,
      );
    }
  }

  @override
  Future<void> deleteSite(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sites.removeWhere((s) => s.id == id);
  }
}
