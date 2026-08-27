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
@RequestMapping("/api/mappings")
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
    public ResponseEntity<ApiResponse<Void>> saveEmployeeMappings(@RequestBody EmployeeSiteMappingRequest request) {
        mappingService.saveEmployeeMappings(request);
        return ResponseEntity.ok(ApiResponse.success("Employee mappings updated successfully", null));
    }

    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Void>> toggleStatus(@PathVariable String id) {
        mappingService.toggleStatus(id);
        return ResponseEntity.ok(ApiResponse.success("Mapping status toggled", null));
    }
}
