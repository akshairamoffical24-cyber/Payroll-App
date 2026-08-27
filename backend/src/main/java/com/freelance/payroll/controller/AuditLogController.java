package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/audit-logs")
public class AuditLogController {

    private final AuditLogService auditLogService;

    @Autowired
    public AuditLogController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<AuditLogEntity>>> getAllLogs() {
        return ResponseEntity.ok(ApiResponse.success(auditLogService.getAllLogs()));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AuditLogEntity>> logAction(@RequestBody AuditLogEntity log) {
        AuditLogEntity created = auditLogService.logAction(
                log.getAction(),
                log.getActorName(),
                log.getActorRole(),
                log.getDetails(),
                log.getTargetEntity()
        );
        return ResponseEntity.ok(ApiResponse.success("Action logged successfully", created));
    }
}
