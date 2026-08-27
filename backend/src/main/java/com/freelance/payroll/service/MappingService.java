package com.freelance.payroll.service;

import com.freelance.payroll.dto.EmployeeSiteMappingRequest;
import com.freelance.payroll.entity.EmployeeSiteMappingEntity;
import com.freelance.payroll.repository.EmployeeSiteMappingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MappingService {

    private final EmployeeSiteMappingRepository mappingRepository;

    @Autowired
    public MappingService(EmployeeSiteMappingRepository mappingRepository) {
        this.mappingRepository = mappingRepository;
    }

    public List<EmployeeSiteMappingEntity> getAllMappings() {
        return mappingRepository.findAll();
    }

    public List<EmployeeSiteMappingEntity> getMappingsForEmployee(String employeeId) {
        return mappingRepository.findByEmployeeId(employeeId);
    }

    public List<String> getActiveSiteIdsForEmployee(String employeeId, LocalDate date) {
        LocalDate checkDate = (date != null) ? date : LocalDate.now();
        return mappingRepository.findByEmployeeIdAndStatusIgnoreCase(employeeId, "active").stream()
                .filter(m -> !checkDate.isBefore(m.getFromDate()) && (m.getToDate() == null || !checkDate.isAfter(m.getToDate())))
                .map(EmployeeSiteMappingEntity::getSiteId)
                .collect(Collectors.toList());
    }

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
                            .fromDate(request.getFromDate())
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

    public void toggleStatus(String id) {
        mappingRepository.findById(id).ifPresent(m -> {
            m.setStatus("active".equalsIgnoreCase(m.getStatus()) ? "inactive" : "active");
            m.setUpdatedDate(LocalDateTime.now());
            mappingRepository.save(m);
        });
    }
}
