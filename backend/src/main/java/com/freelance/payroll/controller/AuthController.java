package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.AuthResponse;
import com.freelance.payroll.dto.GoogleAuthRequest;
import com.freelance.payroll.dto.LoginRequest;
import com.freelance.payroll.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    @Autowired
    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Login successful", response));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");
        AuthResponse response = authService.refreshToken(refreshToken);
        return ResponseEntity.ok(ApiResponse.success("Token refreshed successfully", response));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = authHeader != null && authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        authService.logout(token);
        return ResponseEntity.ok(ApiResponse.success("Logged out successfully", null));
    }

    @PostMapping("/google")
    public ResponseEntity<ApiResponse<AuthResponse>> signInWithGoogle(@RequestBody GoogleAuthRequest request) {
        AuthResponse response = authService.signInWithGoogle(request);
        return ResponseEntity.ok(ApiResponse.success("Google sign-in successful", response));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse>> getCurrentUser(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = authHeader != null && authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;
        return authService.getCurrentUser(token)
                .map(u -> ResponseEntity.ok(ApiResponse.success(u)))
                .orElse(ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("User session expired or not found")));
    }
}
