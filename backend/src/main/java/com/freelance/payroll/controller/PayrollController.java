package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.PayrollRecordEntity;
import com.freelance.payroll.service.PayrollService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/payroll")
public class PayrollController {

    private final PayrollService payrollService;

    @Autowired
    public PayrollController(PayrollService payrollService) {
        this.payrollService = payrollService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PayrollRecordEntity>>> getPayrollForMonth(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate month) {
        LocalDate targetMonth = (month != null) ? month : LocalDate.now().withDayOfMonth(1);
        return ResponseEntity.ok(ApiResponse.success(payrollService.getPayrollForMonth(targetMonth)));
    }

    @PostMapping("/calculate")
    public ResponseEntity<ApiResponse<List<PayrollRecordEntity>>> calculateMonthlyPayroll(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate month) {
        LocalDate targetMonth = (month != null) ? month : LocalDate.now().withDayOfMonth(1);
        return ResponseEntity.ok(ApiResponse.success("Payroll calculated successfully", payrollService.calculateMonthlyPayroll(targetMonth)));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<PayrollRecordEntity>> updateStatus(
            @PathVariable String id,
            @RequestParam String status) {
        PayrollRecordEntity updated = payrollService.updateStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Payroll status updated to " + status, updated));
    }
}
