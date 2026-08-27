package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegularizationSubmissionRequest {
    private String employeeId;
    private String employeeCode;
    private String employeeName;
    private String department;
    private String requestType;
    private String reasonCategory;
    private LocalDate attendanceDate;
    private String requestedInTime;
    private String requestedOutTime;
    private String remarks;
}
