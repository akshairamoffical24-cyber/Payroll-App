package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceRequest {
    private String employeeId;
    private String siteId;
    private Double latitude;
    private Double longitude;
    private String remarks;
    private LocalDateTime timestamp;
}
