package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.service.ReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final ReportService reportService;

    @Autowired
    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/attendance")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAttendanceReport(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ApiResponse.success(reportService.getAttendanceReport(from, to)));
    }

    @GetMapping("/payroll")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPayrollReport(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year) {
        return ResponseEntity.ok(ApiResponse.success(reportService.getPayrollReport(month, year)));
    }

    @GetMapping("/employee")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getEmployeeReport(
            @RequestParam(required = false) String department) {
        return ResponseEntity.ok(ApiResponse.success(reportService.getEmployeeReport(department)));
    }

    @GetMapping("/leave")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLeaveReport(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ApiResponse.success(reportService.getLeaveReport(from, to)));
    }
}
