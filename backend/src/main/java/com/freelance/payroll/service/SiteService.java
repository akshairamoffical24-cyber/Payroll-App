package com.freelance.payroll.service;

import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.entity.SiteEntity;
import com.freelance.payroll.exception.BadRequestException;
import com.freelance.payroll.exception.ResourceNotFoundException;
import com.freelance.payroll.repository.AuditLogRepository;
import com.freelance.payroll.repository.SiteRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class SiteService {

    private final SiteRepository siteRepository;
    private final AuditLogRepository auditLogRepository;

    @Autowired
    public SiteService(SiteRepository siteRepository, AuditLogRepository auditLogRepository) {
        this.siteRepository = siteRepository;
        this.auditLogRepository = auditLogRepository;
    }

    public List<SiteEntity> getAllSites() {
        return siteRepository.findAll();
    }

    public Optional<SiteEntity> getSiteById(String id) {
        return siteRepository.findById(id);
    }

    @Transactional
    public SiteEntity createSite(SiteEntity site) {
        if (site.getCode() == null || site.getCode().isBlank()) {
            site.setCode("SITE" + UUID.randomUUID().toString().substring(0, 5).toUpperCase());
        }
        if (site.getName() == null || site.getName().isBlank()) {
            throw new BadRequestException("Site name is required");
        }
        if (site.getLatitude() == null || site.getLongitude() == null) {
            throw new BadRequestException("Latitude and longitude are required for site geofencing");
        }
        if (site.getGeofenceRadius() == null || site.getGeofenceRadius() <= 0) {
            site.setGeofenceRadius(150.0);
        }

        Optional<SiteEntity> existing = siteRepository.findByCodeIgnoreCase(site.getCode());
        if (existing.isPresent()) {
            throw new BadRequestException("Site code '" + site.getCode() + "' already exists.");
        }

        if (site.getId() == null || site.getId().isBlank()) {
            site.setId("SITE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }
        if (site.getStatus() == null) {
            site.setStatus("active");
        }

        SiteEntity saved = siteRepository.save(site);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("CREATE")
                    .actorName("HR/Admin")
                    .actorRole("HR")
                    .targetEntity("SITE")
                    .details("Site " + saved.getName() + " (" + saved.getCode() + ") created with geofence radius " + saved.getGeofenceRadius() + "m")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public SiteEntity updateSite(String id, SiteEntity site) {
        SiteEntity existing = siteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));

        if (site.getName() != null) existing.setName(site.getName());
        if (site.getClient() != null) existing.setClient(site.getClient());
        if (site.getProject() != null) existing.setProject(site.getProject());
        if (site.getAddress() != null) existing.setAddress(site.getAddress());
        if (site.getLatitude() != null) existing.setLatitude(site.getLatitude());
        if (site.getLongitude() != null) existing.setLongitude(site.getLongitude());
        if (site.getGeofenceRadius() != null && site.getGeofenceRadius() > 0) existing.setGeofenceRadius(site.getGeofenceRadius());
        if (site.getPoNumber() != null) existing.setPoNumber(site.getPoNumber());
        if (site.getSiteManagerName() != null) existing.setSiteManagerName(site.getSiteManagerName());
        if (site.getSiteEngineerName() != null) existing.setSiteEngineerName(site.getSiteEngineerName());
        if (site.getStatus() != null) existing.setStatus(site.getStatus());

        SiteEntity saved = siteRepository.save(existing);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("UPDATE")
                    .actorName("HR/Admin")
                    .actorRole("HR")
                    .targetEntity("SITE")
                    .details("Updated site " + saved.getName() + " (" + saved.getCode() + ")")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public void toggleStatus(String id) {
        siteRepository.findById(id).ifPresent(s -> {
            s.setStatus("active".equalsIgnoreCase(s.getStatus()) ? "inactive" : "active");
            siteRepository.save(s);
        });
    }

    @Transactional
    public void deleteSite(String id) {
        SiteEntity site = siteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));
        siteRepository.delete(site);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("DELETE")
                    .actorName("Admin")
                    .actorRole("ADMIN")
                    .targetEntity("SITE")
                    .details("Deleted site " + site.getName() + " (" + site.getCode() + ")")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}
    }
}
