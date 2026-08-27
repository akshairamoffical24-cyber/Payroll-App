package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {

    private final DataSource dataSource;

    @Autowired
    public HealthController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> healthCheck() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "payroll-attendance-backend");
        health.put("timestamp", System.currentTimeMillis());

        try (Connection conn = dataSource.getConnection()) {
            health.put("database", "CONNECTED");
            health.put("databaseProduct", conn.getMetaData().getDatabaseProductName());
        } catch (Exception e) {
            health.put("database", "DISCONNECTED: " + e.getMessage());
        }

        return ResponseEntity.ok(ApiResponse.success("Service is healthy", health));
    }
}
