package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "leave_requests", indexes = {
    @Index(name = "idx_leave_emp_id", columnList = "employee_id"),
    @Index(name = "idx_leave_status", columnList = "status")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaveRequestEntity {

    @Id
    private String id;

    @Column(name = "employee_id", nullable = false)
    private String employeeId;

    private String employeeCode;
    private String employeeName;
    private String department;

    @Column(nullable = false)
    private String leaveType; // CASUAL, SICK, PAID, UNPAID, MATERNITY

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private LocalDate endDate;

    private Double totalDays;

    @Column(length = 1000)
    private String reason;

    @Column(nullable = false)
    private String status; // PENDING, APPROVED, REJECTED

    private String approvedBy;
    private String reviewerRole;
    private LocalDateTime reviewedAt;
    private String reviewRemarks;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (status == null) status = "PENDING";
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
