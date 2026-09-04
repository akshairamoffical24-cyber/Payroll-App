package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.EmployeeSiteMappingRequest;
import com.freelance.payroll.entity.EmployeeSiteMappingEntity;
import com.freelance.payroll.service.MappingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping({"/api/mappings", "/api/site-mappings"})
public class MappingController {

    private final MappingService mappingService;

    @Autowired
    public MappingController(MappingService mappingService) {
        this.mappingService = mappingService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<EmployeeSiteMappingEntity>>> getAllMappings() {
        return ResponseEntity.ok(ApiResponse.success(mappingService.getAllMappings()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EmployeeSiteMappingEntity>> getMappingById(@PathVariable String id) {
        return mappingService.getMappingById(id)
                .map(m -> ResponseEntity.ok(ApiResponse.success(m)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/employee/{employeeId}")
    public ResponseEntity<ApiResponse<List<EmployeeSiteMappingEntity>>> getMappingsForEmployee(@PathVariable String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(mappingService.getMappingsForEmployee(employeeId)));
    }

    @GetMapping("/employee/{employeeId}/active-sites")
    public ResponseEntity<ApiResponse<List<String>>> getActiveSiteIdsForEmployee(
            @PathVariable String employeeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(ApiResponse.success(mappingService.getActiveSiteIdsForEmployee(employeeId, date)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Object>> createOrUpdateMappings(@RequestBody Object requestBody) {
        if (requestBody instanceof EmployeeSiteMappingRequest req) {
            mappingService.saveEmployeeMappings(req);
            return ResponseEntity.ok(ApiResponse.success("Employee mappings updated successfully", null));
        }
        return ResponseEntity.ok(ApiResponse.success("Employee mappings updated successfully", null));
    }

    @PostMapping("/single")
    public ResponseEntity<ApiResponse<EmployeeSiteMappingEntity>> createSingleMapping(@RequestBody EmployeeSiteMappingEntity mapping) {
        EmployeeSiteMappingEntity created = mappingService.createMapping(mapping);
        return ResponseEntity.ok(ApiResponse.success("Mapping created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<EmployeeSiteMappingEntity>> updateMapping(
            @PathVariable String id, @RequestBody EmployeeSiteMappingEntity mapping) {
        EmployeeSiteMappingEntity updated = mappingService.updateMapping(id, mapping);
        return ResponseEntity.ok(ApiResponse.success("Mapping updated successfully", updated));
    }

    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Void>> toggleStatus(@PathVariable String id) {
        mappingService.toggleStatus(id);
        return ResponseEntity.ok(ApiResponse.success("Mapping status toggled", null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteMapping(@PathVariable String id) {
        mappingService.deleteMapping(id);
        return ResponseEntity.ok(ApiResponse.success("Mapping deleted successfully", null));
    }
}
