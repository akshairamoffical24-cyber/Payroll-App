package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.MobilePunchRequest;
import com.freelance.payroll.dto.PunchSyncRequest;
import com.freelance.payroll.entity.AttendancePunchEntity;
import com.freelance.payroll.entity.DailyAttendanceEntity;
import com.freelance.payroll.service.AttendanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    @Autowired
    public AttendanceController(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    @GetMapping("/punches")
    public ResponseEntity<ApiResponse<List<AttendancePunchEntity>>> getAllPunches() {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getAllPunches()));
    }

    @GetMapping("/daily")
    public ResponseEntity<ApiResponse<List<DailyAttendanceEntity>>> getDailyAttendanceList(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getDailyAttendanceList(date, employeeId)));
    }

    @GetMapping("/daily/employee/{employeeId}")
    public ResponseEntity<ApiResponse<DailyAttendanceEntity>> getDailyAttendanceForEmployee(
            @PathVariable String employeeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate targetDate = (date != null) ? date : LocalDate.now();
        return attendanceService.getDailyAttendanceForEmployee(employeeId, targetDate)
                .map(d -> ResponseEntity.ok(ApiResponse.success(d)))
                .orElse(ResponseEntity.ok(ApiResponse.success("No attendance record found for this date", null)));
    }

    @PostMapping("/punches/mobile")
    public ResponseEntity<ApiResponse<AttendancePunchEntity>> recordMobilePunch(@RequestBody MobilePunchRequest request) {
        AttendancePunchEntity punch = attendanceService.recordMobilePunch(request);
        return ResponseEntity.ok(ApiResponse.success("Mobile punch recorded successfully", punch));
    }

    @PostMapping("/punches/sync")
    public ResponseEntity<ApiResponse<Integer>> syncOfflinePunches(@RequestBody PunchSyncRequest request) {
        int count = attendanceService.syncOfflinePunches(request.getPunches());
        return ResponseEntity.ok(ApiResponse.success("Synced " + count + " offline punches successfully", count));
    }
}
