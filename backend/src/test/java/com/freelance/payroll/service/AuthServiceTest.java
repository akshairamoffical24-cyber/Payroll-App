package com.freelance.payroll.service;

import com.freelance.payroll.dto.AuthResponse;
import com.freelance.payroll.dto.LoginRequest;
import com.freelance.payroll.dto.SendOtpRequest;
import com.freelance.payroll.dto.VerifyOtpRequest;
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

    @Autowired
    private com.freelance.payroll.repository.EmployeeRepository employeeRepository;

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

    @Test
    void testSendOtpAndVerifyOtpSuccess() {
        com.freelance.payroll.entity.EmployeeEntity emp = com.freelance.payroll.entity.EmployeeEntity.builder()
                .id("EMP-TEST-999")
                .code("EMP999")
                .name("Akshairam S")
                .email("test.employee@workpulse.io")
                .phone("6374990354")
                .department("Engineering")
                .designation("Field Lead")
                .type("field")
                .status("active")
                .build();
        employeeRepository.save(emp);

        SendOtpRequest sendReq = SendOtpRequest.builder()
                .mobile("6374990354")
                .build();
        var sendRes = authService.sendOtp(sendReq);
        assertNotNull(sendRes);
        assertEquals("6374990354", sendRes.get("mobile"));
        assertTrue((Boolean) sendRes.get("success"));

        VerifyOtpRequest verifyReq = VerifyOtpRequest.builder()
                .mobile("6374990354")
                .otp("123456")
                .build();
        AuthResponse authRes = authService.verifyOtp(verifyReq);
        assertNotNull(authRes);
        assertNotNull(authRes.getToken());
        assertEquals("fieldStaff", authRes.getRole());
    }

    @Test
    void testVerifyOtpWrongCodeThrowsException() {
        VerifyOtpRequest verifyReq = VerifyOtpRequest.builder()
                .mobile("6374990354")
                .otp("999999")
                .build();
        assertThrows(IllegalArgumentException.class, () -> authService.verifyOtp(verifyReq));
    }
}
