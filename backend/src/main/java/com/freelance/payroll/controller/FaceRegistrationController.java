package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.FaceRegistrationRequest;
import com.freelance.payroll.dto.FaceStatusResponse;
import com.freelance.payroll.service.FaceRegistrationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/face")
@RequiredArgsConstructor
public class FaceRegistrationController {

    private final FaceRegistrationService faceRegistrationService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<FaceStatusResponse>> registerFace(
            @RequestBody FaceRegistrationRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        FaceStatusResponse response = faceRegistrationService.registerFace(request, userId);
        return ResponseEntity.ok(ApiResponse.success("Face biometric template registered successfully", response));
    }

    @GetMapping({"/{employeeId}", "/status/{employeeId}"})
    public ResponseEntity<ApiResponse<FaceStatusResponse>> getFaceStatus(@PathVariable String employeeId) {
        FaceStatusResponse response = faceRegistrationService.getFaceStatus(employeeId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @DeleteMapping("/{employeeId}")
    public ResponseEntity<ApiResponse<FaceStatusResponse>> deleteFaceRegistration(
            @PathVariable String employeeId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        FaceStatusResponse response = faceRegistrationService.invalidateFaceRegistration(employeeId, userId);
        return ResponseEntity.ok(ApiResponse.success("Face registration deleted successfully", response));
    }

    @PostMapping("/invalidate/{employeeId}")
    public ResponseEntity<ApiResponse<FaceStatusResponse>> invalidateFaceRegistration(
            @PathVariable String employeeId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        FaceStatusResponse response = faceRegistrationService.invalidateFaceRegistration(employeeId, userId);
        return ResponseEntity.ok(ApiResponse.success("Face registration revoked successfully", response));
    }
}
