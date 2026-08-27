package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance_punches")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendancePunchEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String employeeId;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(nullable = false)
    private String type; // inPunch, outPunch

    @Column(nullable = false)
    private String source; // mobile, biometric

    private String siteId;
    private String siteName;
    private Double latitude;
    private Double longitude;
    private Double accuracy;
    private Double distanceMeters;
    private Boolean isVerified;
    private Boolean isPendingSync;
}
