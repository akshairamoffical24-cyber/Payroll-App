package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.PayrollItemEntity;
import com.freelance.payroll.entity.PayrollRecordEntity;
import com.freelance.payroll.service.PayrollService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payroll")
public class PayrollController {

    private final PayrollService payrollService;

    @Autowired
    public PayrollController(PayrollService payrollService) {
        this.payrollService = payrollService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<PayrollRecordEntity>>> getPayrollRecords(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year) {
        if (month != null && year != null) {
            return ResponseEntity.ok(ApiResponse.success(payrollService.getPayrollRecordsForMonth(month, year)));
        }
        return ResponseEntity.ok(ApiResponse.success(payrollService.getAllPayrollRecords()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PayrollRecordEntity>> getPayrollById(@PathVariable String id) {
        return payrollService.getPayrollRecordById(id)
                .map(p -> ResponseEntity.ok(ApiResponse.success(p)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/items")
    public ResponseEntity<ApiResponse<List<PayrollItemEntity>>> getPayrollItems(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(payrollService.getPayrollItems(id)));
    }

    @GetMapping("/employee/{employeeId}")
    public ResponseEntity<ApiResponse<List<PayrollRecordEntity>>> getPayrollForEmployee(@PathVariable String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(payrollService.getPayrollRecordsForEmployee(employeeId)));
    }

    @PostMapping({"/generate", "/calculate"})
    public ResponseEntity<ApiResponse<List<PayrollRecordEntity>>> generatePayroll(@RequestBody(required = false) Map<String, Object> body) {
        int month = LocalDate.now().getMonthValue();
        int year = LocalDate.now().getYear();
        String employeeId = null;

        if (body != null) {
            if (body.get("month") != null) month = Integer.parseInt(body.get("month").toString());
            if (body.get("year") != null) year = Integer.parseInt(body.get("year").toString());
            if (body.get("employeeId") != null) employeeId = body.get("employeeId").toString();
        }

        List<PayrollRecordEntity> generated = payrollService.generatePayroll(month, year, employeeId);
        return ResponseEntity.ok(ApiResponse.success("Payroll generated successfully for " + generated.size() + " employees", generated));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<PayrollRecordEntity>> updateStatus(
            @PathVariable String id, @RequestBody Map<String, String> body) {
        String status = body.get("status");
        PayrollRecordEntity updated = payrollService.updateStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Payroll status updated to " + status, updated));
    }
}
