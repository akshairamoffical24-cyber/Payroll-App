package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.SystemSettingsEntity;
import com.freelance.payroll.service.SettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    private final SettingsService settingsService;

    @Autowired
    public SettingsController(SettingsService settingsService) {
        this.settingsService = settingsService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<SystemSettingsEntity>> getSettings() {
        return ResponseEntity.ok(ApiResponse.success(settingsService.getSettings()));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<SystemSettingsEntity>> updateSettings(@RequestBody SystemSettingsEntity settings) {
        return ResponseEntity.ok(ApiResponse.success("Settings updated successfully", settingsService.updateSettings(settings)));
    }
}
