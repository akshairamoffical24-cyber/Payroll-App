package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "daily_attendance")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyAttendanceEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String employeeId;

    @Column(nullable = false)
    private LocalDate date;

    private String firstPunchId;
    private LocalDateTime firstPunchTime;
    private String firstPunchType;
    private String firstPunchSource;
    private String firstPunchSiteName;

    private String lastPunchId;
    private LocalDateTime lastPunchTime;
    private String lastPunchType;
    private String lastPunchSource;
    private String lastPunchSiteName;

    @Column(length = 1000)
    private String visitedSiteNamesJson; // Stored as comma-separated or JSON list

    private Long workingMinutes;

    @Column(nullable = false)
    private String status; // present, late, absent, halfDay, leave, holiday, weeklyOff, permission, onDuty, missingIn, missingOut

    private String sourceType; // mobile, biometric, regularized, system
    private String remarks;
    private Double payrollWorkingDaysCredit;
}
