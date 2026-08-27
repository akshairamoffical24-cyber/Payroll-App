import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/site.dart';
import 'site_repository.dart';

class HttpSiteRepository implements SiteRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<Site>> getAllSites() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.sites);
      if (response is List) {
        return response.map((json) => Site.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[HttpSiteRepo] Error fetching sites: $e');
      rethrow;
    }
  }

  @override
  Future<Site?> getSiteById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.siteById(id));
      if (response is Map<String, dynamic>) {
        return Site.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[HttpSiteRepo] Error fetching site by id ($id): $e');
      return null;
    }
  }

  @override
  Future<Site> addSite(Site site) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.sites, body: site.toJson());
      if (response is Map<String, dynamic>) {
        return Site.fromJson(response);
      }
      throw ApiException('Unexpected response format creating site.');
    } catch (e) {
      debugPrint('[HttpSiteRepo] Error adding site: $e');
      rethrow;
    }
  }

  @override
  Future<Site> updateSite(Site site) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.siteById(site.id), body: site.toJson());
      if (response is Map<String, dynamic>) {
        return Site.fromJson(response);
      }
      throw ApiException('Unexpected response format updating site.');
    } catch (e) {
      debugPrint('[HttpSiteRepo] Error updating site: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleSiteStatus(String id) async {
    try {
      await _apiClient.patch(ApiEndpoints.toggleSiteStatus(id));
    } catch (e) {
      debugPrint('[HttpSiteRepo] Error toggling status: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSite(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.siteById(id));
    } catch (e) {
      debugPrint('[HttpSiteRepo] Error deleting site: $e');
      rethrow;
    }
  }
}
