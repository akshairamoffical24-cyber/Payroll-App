package com.freelance.payroll.dto;

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
public class FaceRegistrationRequest {
    private String employeeId;
    private String faceEmbedding; // Normalized vector embedding representation
    private String modelVersion;
    private Double qualityScore;
    private Double livenessScore;
    private String registrationDevice;
    private Boolean consentAccepted;
}
