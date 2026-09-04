package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "payroll_records", indexes = {
    @Index(name = "idx_payroll_emp_id", columnList = "employee_id"),
    @Index(name = "idx_payroll_month_year", columnList = "payroll_year, payroll_month")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PayrollRecordEntity {

    @Id
    private String id;

    @Column(name = "employee_id", nullable = false)
    private String employeeId;

    private String employeeCode;
    private String employeeName;
    private String department;

    @Column(name = "payroll_month")
    private Integer payrollMonth;

    @Column(name = "payroll_year")
    private Integer payrollYear;

    private LocalDate month; // e.g. 2026-08-01

    private Integer totalDaysInMonth;
    private Double workingDays;
    private Double payableDays;
    private Double presentDays;
    private Double weeklyOffs;
    private Double holidays;
    private Double paidLeaves;
    private Double absentDays;
    private Double leaveDays;
    private Double halfDays;

    private Double basicSalary;
    private Double grossMonthlyCtc;
    private Double grossSalary;
    private Double perDaySalary;
    private Double calculatedPayableSalary;
    private Double deductions;
    private Double netPayableSalary;
    private Double netSalary;

    @Column(nullable = false)
    private String status; // draft, calculated, approved, disbursed

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (status == null) status = "calculated";
        if (month != null) {
            if (payrollMonth == null) payrollMonth = month.getMonthValue();
            if (payrollYear == null) payrollYear = month.getYear();
        }
        if (grossSalary == null) grossSalary = grossMonthlyCtc != null ? grossMonthlyCtc : calculatedPayableSalary;
        if (netSalary == null) netSalary = netPayableSalary;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
