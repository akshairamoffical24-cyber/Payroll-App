package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PayrollResponse {
    private String id;
    private String employeeId;
    private String employeeCode;
    private String employeeName;
    private String department;
    private Integer month;
    private Integer year;
    private Double payableDays;
    private Double grossSalary;
    private Double deductions;
    private Double netSalary;
    private String status;
}
