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
public class MobilePunchRequest {
    private String employeeId;
    private String type; // inPunch, outPunch
    private String siteId;
    private String siteName;
    private Double latitude;
    private Double longitude;
    private Double accuracy;
    private Double distanceMeters;
    private LocalDateTime timestamp;
    private Boolean isOfflineQueued;
}
