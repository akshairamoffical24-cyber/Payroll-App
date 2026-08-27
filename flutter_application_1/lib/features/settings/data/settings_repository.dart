import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class SystemSettings {
  final String id;
  final String companyName;
  final String officeStartTime;
  final String officeEndTime;
  final int workHoursPerDay;
  final int lateGraceMinutes; // e.g. 30 mins after 09:00 AM = 09:30 AM cutoff
  final double defaultGeofenceRadiusMeters;
  final int biometricSyncIntervalMinutes;
  final bool autoSyncOfflinePunches;
  final bool enableAutoPayroll;
  final bool enableBiometricSync;
  final bool allowOfflinePunches;
  final double maxGpsAccuracyThresholdMeters;
  final ThemeMode themeMode;

  const SystemSettings({
    this.id = 'SETTING-PRIMARY',
    this.companyName = 'WorkPulse Enterprise Corp',
    this.officeStartTime = '09:00',
    this.officeEndTime = '18:00',
    this.workHoursPerDay = 8,
    this.lateGraceMinutes = 30,
    this.defaultGeofenceRadiusMeters = 100.0,
    this.biometricSyncIntervalMinutes = 15,
    this.autoSyncOfflinePunches = true,
    this.enableAutoPayroll = true,
    this.enableBiometricSync = true,
    this.allowOfflinePunches = true,
    this.maxGpsAccuracyThresholdMeters = 50.0,
    this.themeMode = ThemeMode.dark,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      id: json['id']?.toString() ?? 'SETTING-PRIMARY',
      companyName: json['companyName']?.toString() ?? 'WorkPulse Enterprise Corp',
      officeStartTime: json['officeStartTime']?.toString() ?? '09:00',
      officeEndTime: json['officeEndTime']?.toString() ?? '18:00',
      workHoursPerDay: 8,
      lateGraceMinutes: (json['lateGraceMinutes'] as num?)?.toInt() ?? 30,
      defaultGeofenceRadiusMeters: (json['defaultGeofenceRadiusMeters'] as num?)?.toDouble() ?? 100.0,
      biometricSyncIntervalMinutes: 15,
      autoSyncOfflinePunches: json['allowOfflinePunches'] == true,
      enableAutoPayroll: json['enableAutoPayroll'] == true,
      enableBiometricSync: json['enableBiometricSync'] == true,
      allowOfflinePunches: json['allowOfflinePunches'] == true,
      maxGpsAccuracyThresholdMeters: (json['maxGpsAccuracyThresholdMeters'] as num?)?.toDouble() ?? 50.0,
      themeMode: ThemeMode.dark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'officeStartTime': officeStartTime,
      'officeEndTime': officeEndTime,
      'lateGraceMinutes': lateGraceMinutes,
      'halfDayThresholdHours': 4,
      'defaultGeofenceRadiusMeters': defaultGeofenceRadiusMeters,
      'enableAutoPayroll': enableAutoPayroll,
      'enableBiometricSync': enableBiometricSync,
      'allowOfflinePunches': allowOfflinePunches,
      'maxGpsAccuracyThresholdMeters': maxGpsAccuracyThresholdMeters,
    };
  }

  SystemSettings copyWith({
    String? id,
    String? companyName,
    String? officeStartTime,
    String? officeEndTime,
    int? workHoursPerDay,
    int? lateGraceMinutes,
    double? defaultGeofenceRadiusMeters,
    int? biometricSyncIntervalMinutes,
    bool? autoSyncOfflinePunches,
    bool? enableAutoPayroll,
    bool? enableBiometricSync,
    bool? allowOfflinePunches,
    double? maxGpsAccuracyThresholdMeters,
    ThemeMode? themeMode,
  }) {
    return SystemSettings(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      officeStartTime: officeStartTime ?? this.officeStartTime,
      officeEndTime: officeEndTime ?? this.officeEndTime,
      workHoursPerDay: workHoursPerDay ?? this.workHoursPerDay,
      lateGraceMinutes: lateGraceMinutes ?? this.lateGraceMinutes,
      defaultGeofenceRadiusMeters: defaultGeofenceRadiusMeters ?? this.defaultGeofenceRadiusMeters,
      biometricSyncIntervalMinutes: biometricSyncIntervalMinutes ?? this.biometricSyncIntervalMinutes,
      autoSyncOfflinePunches: autoSyncOfflinePunches ?? this.autoSyncOfflinePunches,
      enableAutoPayroll: enableAutoPayroll ?? this.enableAutoPayroll,
      enableBiometricSync: enableBiometricSync ?? this.enableBiometricSync,
      allowOfflinePunches: allowOfflinePunches ?? this.allowOfflinePunches,
      maxGpsAccuracyThresholdMeters: maxGpsAccuracyThresholdMeters ?? this.maxGpsAccuracyThresholdMeters,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

abstract class SettingsRepository {
  Future<SystemSettings> getSettings();
  Future<void> updateSettings(SystemSettings settings);
}

class HttpSettingsRepository implements SettingsRepository {
  final ApiClient _apiClient = ApiClient();
  SystemSettings _cached = const SystemSettings();

  @override
  Future<SystemSettings> getSettings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.settings);
      if (response is Map<String, dynamic>) {
        _cached = SystemSettings.fromJson(response);
        return _cached;
      }
    } catch (e) {
      debugPrint('[HttpSettingsRepo] Error fetching settings: $e');
    }
    return _cached;
  }

  @override
  Future<void> updateSettings(SystemSettings settings) async {
    _cached = settings;
    try {
      await _apiClient.put(ApiEndpoints.settings, body: settings.toJson());
    } catch (e) {
      debugPrint('[HttpSettingsRepo] Error updating settings: $e');
      rethrow;
    }
  }
}
