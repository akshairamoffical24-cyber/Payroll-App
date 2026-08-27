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
public class BiometricPunchRequest {
    private String employeeCode;
    private LocalDateTime timestamp;
    private String deviceSerial;
    private String terminalLocation;
}
