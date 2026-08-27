package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.RegularizationReviewRequest;
import com.freelance.payroll.dto.RegularizationSubmissionRequest;
import com.freelance.payroll.entity.RegularizationRequestEntity;
import com.freelance.payroll.service.RegularizationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/regularization")
public class RegularizationController {

    private final RegularizationService regularizationService;

    @Autowired
    public RegularizationController(RegularizationService regularizationService) {
        this.regularizationService = regularizationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RegularizationRequestEntity>>> getAllRequests() {
        return ResponseEntity.ok(ApiResponse.success(regularizationService.getAllRequests()));
    }

    @GetMapping("/employee/{employeeId}")
    public ResponseEntity<ApiResponse<List<RegularizationRequestEntity>>> getRequestsForEmployee(@PathVariable String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(regularizationService.getRequestsForEmployee(employeeId)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RegularizationRequestEntity>> submitRequest(@RequestBody RegularizationSubmissionRequest request) {
        RegularizationRequestEntity created = regularizationService.submitRequest(request);
        return ResponseEntity.ok(ApiResponse.success("Regularization request submitted successfully", created));
    }

    @PostMapping("/{id}/review")
    public ResponseEntity<ApiResponse<RegularizationRequestEntity>> reviewRequest(
            @PathVariable String id,
            @RequestBody RegularizationReviewRequest reviewRequest) {
        RegularizationRequestEntity reviewed = regularizationService.reviewRequest(id, reviewRequest);
        return ResponseEntity.ok(ApiResponse.success("Request " + reviewRequest.getStatus() + " successfully", reviewed));
    }
}
