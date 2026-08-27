package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "regularization_requests")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegularizationRequestEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String employeeId;

    private String employeeCode;
    private String employeeName;
    private String department;
    private String requestType; // Late Punch IN, Missed / Late Punch OUT, Both IN & OUT
    private String reasonCategory;

    @Column(nullable = false)
    private LocalDate attendanceDate;

    private String requestedInTime;
    private String requestedOutTime;

    @Column(length = 1000)
    private String remarks;

    private LocalDateTime appliedAt;

    @Column(nullable = false)
    private String status; // pending, approved, rejected

    private String reviewedBy;
    private LocalDateTime reviewedAt;
    private String reviewComments;
}
