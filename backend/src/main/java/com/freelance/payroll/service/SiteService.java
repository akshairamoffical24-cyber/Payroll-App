package com.freelance.payroll.service;

import com.freelance.payroll.entity.SiteEntity;
import com.freelance.payroll.repository.SiteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class SiteService {

    private final SiteRepository siteRepository;

    @Autowired
    public SiteService(SiteRepository siteRepository) {
        this.siteRepository = siteRepository;
    }

    public List<SiteEntity> getAllSites() {
        return siteRepository.findAll();
    }

    public Optional<SiteEntity> getSiteById(String id) {
        return siteRepository.findById(id);
    }

    public SiteEntity createSite(SiteEntity site) {
        if (site.getId() == null || site.getId().isEmpty()) {
            site.setId("SITE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }
        if (site.getStatus() == null) {
            site.setStatus("active");
        }
        return siteRepository.save(site);
    }

    public SiteEntity updateSite(String id, SiteEntity site) {
        site.setId(id);
        return siteRepository.save(site);
    }

    public void toggleStatus(String id) {
        siteRepository.findById(id).ifPresent(s -> {
            s.setStatus("active".equalsIgnoreCase(s.getStatus()) ? "inactive" : "active");
            siteRepository.save(s);
        });
    }

    public void deleteSite(String id) {
        siteRepository.deleteById(id);
    }
}
