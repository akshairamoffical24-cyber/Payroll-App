package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {
    private String username;
    private String emailOrId;
    private String password;

    public String getEffectiveUsername() {
        if (username != null && !username.isBlank()) return username.trim();
        if (emailOrId != null && !emailOrId.isBlank()) return emailOrId.trim();
        return "";
    }
}
