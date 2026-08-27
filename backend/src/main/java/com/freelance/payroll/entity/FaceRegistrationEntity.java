package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "employee_face_registration", indexes = {
    @Index(name = "idx_face_emp_status", columnList = "employee_id, registration_status")
})
public class FaceRegistrationEntity {

    @Id
    @Column(length = 64)
    private String id;

    @Column(name = "employee_id", nullable = false, length = 64)
    private String employeeId;

    // Encrypted / isolated 128-d or 512-d normalized biometric vector string
    @Column(name = "biometric_template", nullable = false, columnDefinition = "TEXT")
    private String biometricTemplate;

    @Column(name = "model_version", length = 32, nullable = false)
    private String modelVersion;

    @Column(name = "quality_score")
    private Double qualityScore;

    @Column(name = "liveness_score")
    private Double livenessScore;

    @Column(name = "registration_status", length = 32, nullable = false)
    private String registrationStatus; // ACTIVE, SUPERSEDED, REVOKED

    @Column(name = "registration_device", length = 64)
    private String registrationDevice;

    @Column(name = "registered_at", nullable = false)
    private LocalDateTime registeredAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "registered_by", length = 64)
    private String registeredBy;
}
