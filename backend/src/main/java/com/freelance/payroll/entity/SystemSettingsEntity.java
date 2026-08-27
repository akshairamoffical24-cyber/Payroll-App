package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "system_settings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemSettingsEntity {

    @Id
    private String id;

    private String companyName;
    private String officeStartTime;
    private String officeEndTime;
    private Integer lateGraceMinutes;
    private Integer halfDayThresholdHours;
    private Double defaultGeofenceRadiusMeters;
    private Boolean enableAutoPayroll;
    private Boolean enableBiometricSync;
    private Boolean allowOfflinePunches;
    private Double maxGpsAccuracyThresholdMeters;
}
