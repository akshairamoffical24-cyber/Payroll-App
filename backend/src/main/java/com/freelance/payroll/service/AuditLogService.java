package com.freelance.payroll.service;

import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.repository.AuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    @Autowired
    public AuditLogService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public List<AuditLogEntity> getAllLogs() {
        return auditLogRepository.findAllByOrderByTimestampDesc();
    }

    public AuditLogEntity logAction(String action, String actorName, String actorRole, String details, String targetEntity) {
        AuditLogEntity entity = AuditLogEntity.builder()
                .id("AUDIT-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .action(action)
                .actorName(actorName)
                .actorRole(actorRole)
                .details(details)
                .timestamp(LocalDateTime.now())
                .targetEntity(targetEntity)
                .build();
        return auditLogRepository.save(entity);
    }
}
