package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardResponse {
    private String role;
    private long totalEmployees;
    private long activeEmployees;
    private long inactiveEmployees;
    private long presentToday;
    private long lateToday;
    private long absentToday;
    private long onLeaveToday;
    private long activeSites;
    private long pendingLeaveRequests;
    private Map<String, Object> currentPayrollSummary;
}
