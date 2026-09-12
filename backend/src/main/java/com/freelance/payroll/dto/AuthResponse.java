package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String id;
    private String username;
    private String email;
    private String name;
    private String role;
    private String employeeId;
    private String employeeCode;
    private String department;
    private String designation;
    private String phone;
    private Double monthlyCtc;
    private String avatarUrl;
    private String token;
    private String refreshToken;
}
