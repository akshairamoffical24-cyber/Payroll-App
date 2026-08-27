import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/user.dart';
import 'auth_repository.dart';
import 'google_auth_service.dart';

class HttpAuthRepository implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  User? _currentUser;

  static const String _kUserPrefKey = 'workpulse_auth_user';
  static const String _kTokenPrefKey = 'workpulse_auth_token';

  HttpAuthRepository() {
    _apiClient.setOnUnauthorized(() {
      logout();
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_kTokenPrefKey);
      if (savedToken != null && savedToken.isNotEmpty) {
        _apiClient.setAuthToken(savedToken);
        final response = await _apiClient.get(ApiEndpoints.currentUser);
        if (response is Map<String, dynamic>) {
          _currentUser = User.fromJson(response);
          await _persistUser(_currentUser!, savedToken);
          return _currentUser;
        }
      }
    } catch (e) {
      debugPrint('[HttpAuthRepo] Error verifying current user session: $e');
    }
    return null;
  }

  @override
  Future<User> login({required String emailOrId, required String password}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {'emailOrId': emailOrId.trim(), 'password': password},
      );
      if (response is Map<String, dynamic>) {
        final user = User.fromJson(response);
        _currentUser = user;
        _apiClient.setAuthToken(user.token);
        if (user.token != null) {
          await _persistUser(user, user.token!);
        }
        return user;
      }
      throw ApiException('Unexpected response format received from server.');
    } on ApiException catch (e) {
      debugPrint('[HttpAuthRepo] Login rejected: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[HttpAuthRepo] Login API error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<User> signInWithGoogle({GoogleAuthPayload? payload}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.googleLogin,
        body: payload != null ? payload.toJson() : {},
      );
      if (response is Map<String, dynamic>) {
        final user = User.fromJson(response);
        _currentUser = user;
        _apiClient.setAuthToken(user.token);
        if (user.token != null) {
          await _persistUser(user, user.token!);
        }
        return user;
      }
      throw ApiException('Unexpected response format from Google sign-in.');
    } on ApiException catch (e) {
      debugPrint('[HttpAuthRepo] Backend Google login rejection: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[HttpAuthRepo] Google login network error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _apiClient.setAuthToken(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserPrefKey);
      await prefs.remove(_kTokenPrefKey);
    } catch (e) {
      debugPrint('[HttpAuthRepo] Error clearing preferences on logout: $e');
    }
  }

  Future<void> _persistUser(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenPrefKey, token);
      await prefs.setString(_kUserPrefKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('[HttpAuthRepo] Failed to cache auth user: $e');
    }
  }
}
