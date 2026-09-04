package com.freelance.payroll.service;

import com.freelance.payroll.dto.AuthResponse;
import com.freelance.payroll.dto.LoginRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class AuthServiceTest {

    @Autowired
    private AuthService authService;

    @Test
    void testSuccessfulLogin() {
        LoginRequest request = LoginRequest.builder()
                .emailOrId("admin@workpulse.com")
                .password("admin123")
                .build();

        AuthResponse response = authService.login(request);

        assertNotNull(response);
        assertNotNull(response.getToken());
        assertEquals("ADMIN", response.getRole().toUpperCase());
        assertEquals("admin@workpulse.com", response.getEmail());
    }

    @Test
    void testInvalidPasswordThrowsException() {
        LoginRequest request = LoginRequest.builder()
                .emailOrId("admin@workpulse.com")
                .password("wrongpassword")
                .build();

        assertThrows(IllegalArgumentException.class, () -> authService.login(request));
    }
}
