package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.SiteEntity;
import com.freelance.payroll.service.SiteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/sites")
public class SiteController {

    private final SiteService siteService;

    @Autowired
    public SiteController(SiteService siteService) {
        this.siteService = siteService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<SiteEntity>>> getAllSites() {
        return ResponseEntity.ok(ApiResponse.success(siteService.getAllSites()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SiteEntity>> getSiteById(@PathVariable String id) {
        return siteService.getSiteById(id)
                .map(s -> ResponseEntity.ok(ApiResponse.success(s)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SiteEntity>> createSite(@RequestBody SiteEntity site) {
        SiteEntity created = siteService.createSite(site);
        return ResponseEntity.ok(ApiResponse.success("Site created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<SiteEntity>> updateSite(@PathVariable String id, @RequestBody SiteEntity site) {
        SiteEntity updated = siteService.updateSite(id, site);
        return ResponseEntity.ok(ApiResponse.success("Site updated successfully", updated));
    }

    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Void>> toggleStatus(@PathVariable String id) {
        siteService.toggleStatus(id);
        return ResponseEntity.ok(ApiResponse.success("Site status toggled", null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteSite(@PathVariable String id) {
        siteService.deleteSite(id);
        return ResponseEntity.ok(ApiResponse.success("Site deleted successfully", null));
    }
}
