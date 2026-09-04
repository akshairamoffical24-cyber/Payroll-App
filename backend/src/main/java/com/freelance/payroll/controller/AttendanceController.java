package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.AttendanceRequest;
import com.freelance.payroll.dto.MobilePunchRequest;
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

    @PostMapping("/check-in")
    public ResponseEntity<ApiResponse<DailyAttendanceEntity>> checkIn(@RequestBody AttendanceRequest request) {
        DailyAttendanceEntity attendance = attendanceService.checkIn(request);
        return ResponseEntity.ok(ApiResponse.success("Checked in successfully", attendance));
    }

    @PostMapping("/check-out")
    public ResponseEntity<ApiResponse<DailyAttendanceEntity>> checkOut(@RequestBody AttendanceRequest request) {
        DailyAttendanceEntity attendance = attendanceService.checkOut(request);
        return ResponseEntity.ok(ApiResponse.success("Checked out successfully", attendance));
    }

    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<DailyAttendanceEntity>>> getTodayAttendance() {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getTodayAttendance()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DailyAttendanceEntity>> getAttendanceById(@PathVariable String id) {
        return attendanceService.getAttendanceById(id)
                .map(a -> ResponseEntity.ok(ApiResponse.success(a)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping({"/employee/{employeeId}", "/daily/employee/{employeeId}"})
    public ResponseEntity<ApiResponse<List<DailyAttendanceEntity>>> getAttendanceByEmployee(@PathVariable String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getAttendanceByEmployee(employeeId)));
    }

    @GetMapping("/date/{date}")
    public ResponseEntity<ApiResponse<List<DailyAttendanceEntity>>> getAttendanceByDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getAttendanceByDate(date)));
    }

    @GetMapping("/range")
    public ResponseEntity<ApiResponse<List<DailyAttendanceEntity>>> getAttendanceRange(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getAttendanceRange(from, to)));
    }

    @GetMapping({"", "/daily"})
    public ResponseEntity<ApiResponse<List<DailyAttendanceEntity>>> getDailyAttendance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getDailyAttendanceList(date, employeeId)));
    }

    @PostMapping({"/punch", "/punches/mobile"})
    public ResponseEntity<ApiResponse<AttendancePunchEntity>> recordPunch(@RequestBody MobilePunchRequest request) {
        AttendancePunchEntity punch = attendanceService.recordMobilePunch(request);
        return ResponseEntity.ok(ApiResponse.success("Punch recorded successfully", punch));
    }

    @GetMapping("/punches")
    public ResponseEntity<ApiResponse<List<AttendancePunchEntity>>> getAllPunches() {
        return ResponseEntity.ok(ApiResponse.success(attendanceService.getAllPunches()));
    }
}
