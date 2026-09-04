package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.service.DashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    @Autowired
    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/admin")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAdminDashboard() {
        return ResponseEntity.ok(ApiResponse.success(dashboardService.getAdminDashboardMetrics()));
    }

    @GetMapping("/hr")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHrDashboard() {
        return ResponseEntity.ok(ApiResponse.success(dashboardService.getHrDashboardMetrics()));
    }
}
