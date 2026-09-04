package com.freelance.payroll.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleAuthRequest {

    @JsonAlias({"credential", "id_token", "token"})
    private String idToken;

    private String email;
    private String name;
    private String avatarUrl;
    
    @JsonAlias({"googleId", "google_id", "sub"})
    private String googleSubjectId;

    public String getEffectiveToken() {
        if (idToken != null && !idToken.isBlank()) {
            return idToken.trim();
        }
        return null;
    }

    public String getGoogleId() {
        return googleSubjectId;
    }

    public String getPhotoUrl() {
        return avatarUrl;
    }
}
