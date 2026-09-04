package com.freelance.payroll.service;

import com.freelance.payroll.dto.EmployeeSiteMappingRequest;
import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.entity.EmployeeSiteMappingEntity;
import com.freelance.payroll.exception.ResourceNotFoundException;
import com.freelance.payroll.repository.AuditLogRepository;
import com.freelance.payroll.repository.EmployeeSiteMappingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MappingService {

    private final EmployeeSiteMappingRepository mappingRepository;
    private final AuditLogRepository auditLogRepository;

    @Autowired
    public MappingService(EmployeeSiteMappingRepository mappingRepository, AuditLogRepository auditLogRepository) {
        this.mappingRepository = mappingRepository;
        this.auditLogRepository = auditLogRepository;
    }

    public List<EmployeeSiteMappingEntity> getAllMappings() {
        return mappingRepository.findAll();
    }

    public Optional<EmployeeSiteMappingEntity> getMappingById(String id) {
        return mappingRepository.findById(id);
    }

    public List<EmployeeSiteMappingEntity> getMappingsForEmployee(String employeeId) {
        return mappingRepository.findByEmployeeId(employeeId);
    }

    public List<String> getActiveSiteIdsForEmployee(String employeeId, LocalDate date) {
        LocalDate checkDate = (date != null) ? date : LocalDate.now();
        return mappingRepository.findByEmployeeIdAndStatusIgnoreCase(employeeId, "active").stream()
                .filter(m -> !checkDate.isBefore(m.getFromDate()) && (m.getToDate() == null || !checkDate.isAfter(m.getToDate())))
                .map(m -> m.getSiteId())
                .collect(Collectors.toList());
    }

    public boolean isEmployeeAssignedToSite(String employeeId, String siteId, LocalDate date) {
        List<String> activeSites = getActiveSiteIdsForEmployee(employeeId, date);
        return activeSites.contains(siteId);
    }

    @Transactional
    public EmployeeSiteMappingEntity createMapping(EmployeeSiteMappingEntity mapping) {
        if (mapping.getId() == null || mapping.getId().isBlank()) {
            mapping.setId("MAP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }
        if (mapping.getFromDate() == null) {
            mapping.setFromDate(LocalDate.now());
        }
        if (mapping.getStatus() == null) {
            mapping.setStatus("active");
        }
        mapping.setCreatedDate(LocalDateTime.now());
        EmployeeSiteMappingEntity saved = mappingRepository.save(mapping);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("CREATE_SITE_MAPPING")
                    .actorName(mapping.getCreatedBy() != null ? mapping.getCreatedBy() : "HR/Admin")
                    .actorRole("HR")
                    .targetEntity("EMPLOYEE_SITE_MAPPING")
                    .details("Mapped employee " + mapping.getEmployeeId() + " to site " + mapping.getSiteId())
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public EmployeeSiteMappingEntity updateMapping(String id, EmployeeSiteMappingEntity mapping) {
        EmployeeSiteMappingEntity existing = mappingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mapping not found with id: " + id));

        if (mapping.getSiteId() != null) existing.setSiteId(mapping.getSiteId());
        if (mapping.getFromDate() != null) existing.setFromDate(mapping.getFromDate());
        if (mapping.getToDate() != null) existing.setToDate(mapping.getToDate());
        if (mapping.getStatus() != null) existing.setStatus(mapping.getStatus());
        existing.setUpdatedDate(LocalDateTime.now());

        return mappingRepository.save(existing);
    }

    @Transactional
    public void deleteMapping(String id) {
        EmployeeSiteMappingEntity existing = mappingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Mapping not found with id: " + id));
        mappingRepository.delete(existing);
    }

    @Transactional
    public void saveEmployeeMappings(EmployeeSiteMappingRequest request) {
        LocalDateTime now = LocalDateTime.now();
        List<EmployeeSiteMappingEntity> existing = mappingRepository.findByEmployeeId(request.getEmployeeId());

        // Inactivate unselected sites
        for (EmployeeSiteMappingEntity map : existing) {
            if (request.getSiteIds() == null || !request.getSiteIds().contains(map.getSiteId())) {
                map.setStatus("inactive");
                map.setUpdatedDate(now);
                mappingRepository.save(map);
            }
        }

        // Activate or create selected sites
        if (request.getSiteIds() != null) {
            for (String siteId : request.getSiteIds()) {
                Optional<EmployeeSiteMappingEntity> existingOpt = existing.stream()
                        .filter(m -> m.getSiteId().equals(siteId))
                        .findFirst();

                if (existingOpt.isPresent()) {
                    EmployeeSiteMappingEntity map = existingOpt.get();
                    map.setStatus("active");
                    map.setFromDate(request.getFromDate());
                    map.setToDate(request.getToDate());
                    map.setUpdatedDate(now);
                    mappingRepository.save(map);
                } else {
                    EmployeeSiteMappingEntity newMap = EmployeeSiteMappingEntity.builder()
                            .id("MAP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                            .employeeId(request.getEmployeeId())
                            .siteId(siteId)
                            .fromDate(request.getFromDate() != null ? request.getFromDate() : LocalDate.now())
                            .toDate(request.getToDate())
                            .status("active")
                            .createdBy(request.getActorName() != null ? request.getActorName() : "HR")
                            .createdDate(now)
                            .build();
                    mappingRepository.save(newMap);
                }
            }
        }
    }

    @Transactional
    public void toggleStatus(String id) {
        mappingRepository.findById(id).ifPresent(m -> {
            m.setStatus("active".equalsIgnoreCase(m.getStatus()) ? "inactive" : "active");
            m.setUpdatedDate(LocalDateTime.now());
            mappingRepository.save(m);
        });
    }
}
