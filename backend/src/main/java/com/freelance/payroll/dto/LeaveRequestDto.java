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
public class LeaveRequestDto {
    private String employeeId;
    private String leaveType;
    private LocalDate startDate;
    private LocalDate endDate;
    private String reason;
}
