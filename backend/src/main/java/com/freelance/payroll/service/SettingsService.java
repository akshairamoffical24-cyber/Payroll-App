package com.freelance.payroll.service;

import com.freelance.payroll.entity.SystemSettingsEntity;
import com.freelance.payroll.repository.SystemSettingsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SettingsService {

    private final SystemSettingsRepository settingsRepository;

    @Autowired
    public SettingsService(SystemSettingsRepository settingsRepository) {
        this.settingsRepository = settingsRepository;
    }

    public SystemSettingsEntity getSettings() {
        return settingsRepository.findById("SYS-SETTINGS-001")
                .orElse(SystemSettingsEntity.builder()
                        .id("SYS-SETTINGS-001")
                        .companyName("WorkPulse Enterprise Technologies Ltd.")
                        .officeStartTime("09:00 AM")
                        .officeEndTime("06:00 PM")
                        .lateGraceMinutes(30)
                        .halfDayThresholdHours(4)
                        .defaultGeofenceRadiusMeters(200.0)
                        .enableAutoPayroll(true)
                        .enableBiometricSync(true)
                        .allowOfflinePunches(true)
                        .maxGpsAccuracyThresholdMeters(50.0)
                        .build());
    }

    public SystemSettingsEntity updateSettings(SystemSettingsEntity settings) {
        settings.setId("SYS-SETTINGS-001");
        return settingsRepository.save(settings);
    }
}
