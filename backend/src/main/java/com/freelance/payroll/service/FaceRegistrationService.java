package com.freelance.payroll.service;

import com.freelance.payroll.dto.FaceRegistrationRequest;
import com.freelance.payroll.dto.FaceStatusResponse;
import com.freelance.payroll.entity.*;
import com.freelance.payroll.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class FaceRegistrationService {

    private final FaceRegistrationRepository faceRegistrationRepository;
    private final EmployeeRepository employeeRepository;
    private final UserRepository userRepository;
    private final AuditLogRepository auditLogRepository;
    private final NotificationRepository notificationRepository;

    @Transactional
    public FaceStatusResponse registerFace(FaceRegistrationRequest request, String authenticatedUserId) {
        if (request.getEmployeeId() == null || request.getEmployeeId().trim().isEmpty()) {
            throw new IllegalArgumentException("Employee ID is required for face registration.");
        }

        if (Boolean.FALSE.equals(request.getConsentAccepted())) {
            throw new IllegalArgumentException("Biometric data consent must be explicitly accepted before registration.");
        }

        if (request.getFaceEmbedding() == null || request.getFaceEmbedding().trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid biometric payload: Face template embedding cannot be empty.");
        }

        EmployeeEntity employee = employeeRepository.findById(request.getEmployeeId())
                .orElseThrow(() -> new IllegalArgumentException("Employee not found with ID: " + request.getEmployeeId()));

        if (!"active".equalsIgnoreCase(employee.getStatus())) {
            throw new IllegalStateException("Face registration is only permitted for active employees.");
        }

        // Security check: If authenticatedUserId is present and not admin/HR, verify identity match
        if (authenticatedUserId != null && !authenticatedUserId.trim().isEmpty()) {
            Optional<UserEntity> userOpt = userRepository.findById(authenticatedUserId);
            if (userOpt.isPresent()) {
                UserEntity user = userOpt.get();
                if ("field_staff".equalsIgnoreCase(user.getRole())) {
                    if (user.getEmployeeId() != null && !user.getEmployeeId().equalsIgnoreCase(employee.getId())) {
                        throw new SecurityException("Access Denied: You cannot register biometrics for another employee.");
                    }
                }
            }
        }

        LocalDateTime now = LocalDateTime.now();

        // 1. Create new active face registration record
        FaceRegistrationEntity newRecord = FaceRegistrationEntity.builder()
                .id("FACE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .employeeId(employee.getId())
                .biometricTemplate(request.getFaceEmbedding().trim())
                .modelVersion(request.getModelVersion() != null ? request.getModelVersion() : "WP-FACE-V1.0")
                .qualityScore(request.getQualityScore() != null ? request.getQualityScore() : 0.95)
                .livenessScore(request.getLivenessScore() != null ? request.getLivenessScore() : 0.98)
                .registrationStatus("ACTIVE")
                .registrationDevice(request.getRegistrationDevice() != null ? request.getRegistrationDevice() : "FRONT_CAMERA")
                .registeredAt(now)
                .updatedAt(now)
                .registeredBy(authenticatedUserId != null ? authenticatedUserId : employee.getId())
                .build();

        FaceRegistrationEntity saved = faceRegistrationRepository.save(newRecord);

        // 2. Mark any previous ACTIVE registrations for this employee as SUPERSEDED
        List<FaceRegistrationEntity> allRegistrations = faceRegistrationRepository.findByEmployeeIdOrderByRegisteredAtDesc(employee.getId());
        for (FaceRegistrationEntity existing : allRegistrations) {
            if (!existing.getId().equals(saved.getId()) && "ACTIVE".equalsIgnoreCase(existing.getRegistrationStatus())) {
                existing.setRegistrationStatus("SUPERSEDED");
                existing.setUpdatedAt(now);
                faceRegistrationRepository.save(existing);
            }
        }

        // 3. Update Employee metadata flags
        employee.setIsFaceRegistered(true);
        employee.setFaceRegisteredAt(now);
        employeeRepository.save(employee);

        // 4. Audit Log (Strictly without biometric vector or raw image)
        AuditLogEntity audit = new AuditLogEntity();
        audit.setId("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        audit.setAction("FACE_REGISTERED");
        audit.setActorName(employee.getName());
        audit.setActorRole("EMPLOYEE");
        audit.setTargetEntity("EMPLOYEE:" + employee.getId());
        audit.setDetails("Employee " + employee.getCode() + " (" + employee.getName() + ") completed secure face biometric registration.");
        audit.setTimestamp(now);
        auditLogRepository.save(audit);

        // 5. In-app Notification
        NotificationEntity notif = new NotificationEntity();
        notif.setId("NOTIF-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        notif.setTitle("Face Biometrics Registered");
        notif.setMessage("Your face template has been successfully registered and active for verified attendance capture.");
        notif.setType("success");
        notif.setCategory("security");
        notif.setActionRoute("/profile");
        notif.setTimestamp(now);
        notif.setIsRead(false);
        notificationRepository.save(notif);

        log.info("Face registration successfully completed for employee: {}", employee.getCode());

        return FaceStatusResponse.builder()
                .employeeId(employee.getId())
                .isRegistered(true)
                .status("ACTIVE")
                .modelVersion(saved.getModelVersion())
                .registrationDevice(saved.getRegistrationDevice())
                .registeredAt(saved.getRegisteredAt())
                .updatedAt(saved.getUpdatedAt())
                .build();
    }

    public FaceStatusResponse getFaceStatus(String employeeId) {
        Optional<FaceRegistrationEntity> activeOpt = faceRegistrationRepository
                .findByEmployeeIdAndRegistrationStatus(employeeId, "ACTIVE");

        if (activeOpt.isPresent()) {
            FaceRegistrationEntity reg = activeOpt.get();
            return FaceStatusResponse.builder()
                    .employeeId(employeeId)
                    .isRegistered(true)
                    .status("ACTIVE")
                    .modelVersion(reg.getModelVersion())
                    .registrationDevice(reg.getRegistrationDevice())
                    .registeredAt(reg.getRegisteredAt())
                    .updatedAt(reg.getUpdatedAt())
                    .build();
        }

        return FaceStatusResponse.builder()
                .employeeId(employeeId)
                .isRegistered(false)
                .status("NOT_REGISTERED")
                .build();
    }

    @Transactional
    public FaceStatusResponse invalidateFaceRegistration(String employeeId, String actorUserId) {
        EmployeeEntity employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found: " + employeeId));

        List<FaceRegistrationEntity> registrations = faceRegistrationRepository.findByEmployeeIdOrderByRegisteredAtDesc(employeeId);
        LocalDateTime now = LocalDateTime.now();

        for (FaceRegistrationEntity reg : registrations) {
            if ("ACTIVE".equalsIgnoreCase(reg.getRegistrationStatus())) {
                reg.setRegistrationStatus("REVOKED");
                reg.setUpdatedAt(now);
                faceRegistrationRepository.save(reg);
            }
        }

        employee.setIsFaceRegistered(false);
        employeeRepository.save(employee);

        // Audit Log
        AuditLogEntity audit = new AuditLogEntity();
        audit.setId("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        audit.setAction("FACE_REGISTRATION_REVOKED");
        audit.setActorName(actorUserId != null ? actorUserId : "Administrator");
        audit.setActorRole("ADMIN");
        audit.setTargetEntity("EMPLOYEE:" + employeeId);
        audit.setDetails("Biometric face registration for employee " + employee.getCode() + " was revoked/reset by administrator.");
        audit.setTimestamp(now);
        auditLogRepository.save(audit);

        return FaceStatusResponse.builder()
                .employeeId(employeeId)
                .isRegistered(false)
                .status("REVOKED")
                .updatedAt(now)
                .build();
    }
}
