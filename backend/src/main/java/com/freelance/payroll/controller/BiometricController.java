package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.BiometricPunchRequest;
import com.freelance.payroll.service.BiometricService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/biometric")
public class BiometricController {

    private final BiometricService biometricService;

    @Autowired
    public BiometricController(BiometricService biometricService) {
        this.biometricService = biometricService;
    }

    @PostMapping("/ingest")
    public ResponseEntity<ApiResponse<Void>> ingestBiometricPunch(@RequestBody BiometricPunchRequest request) {
        biometricService.ingestBiometricPunch(request);
        return ResponseEntity.ok(ApiResponse.success("Biometric punch ingested successfully", null));
    }
}
