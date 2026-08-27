package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "payroll_records")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PayrollRecordEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String employeeId;

    @Column(name = "payroll_month", nullable = false)
    private LocalDate month; // e.g. 2026-08-01

    private Integer totalDaysInMonth;
    private Double payableDays;
    private Double presentDays;
    private Double weeklyOffs;
    private Double holidays;
    private Double paidLeaves;
    private Double absentDays;
    private Double halfDays;
    private Double grossMonthlyCtc;
    private Double perDaySalary;
    private Double calculatedPayableSalary;
    private Double deductions;
    private Double netPayableSalary;

    @Column(nullable = false)
    private String status; // draft, calculated, approved, disbursed
}
