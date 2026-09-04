package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.LeaveRequestEntity;
import com.freelance.payroll.service.LeaveService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/leaves")
public class LeaveController {

    private final LeaveService leaveService;

    @Autowired
    public LeaveController(LeaveService leaveService) {
        this.leaveService = leaveService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<LeaveRequestEntity>>> getAllLeaves() {
        return ResponseEntity.ok(ApiResponse.success(leaveService.getAllLeaves()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<LeaveRequestEntity>> getLeaveById(@PathVariable String id) {
        return leaveService.getLeaveById(id)
                .map(l -> ResponseEntity.ok(ApiResponse.success(l)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/employee/{employeeId}")
    public ResponseEntity<ApiResponse<List<LeaveRequestEntity>>> getLeavesByEmployee(@PathVariable String employeeId) {
        return ResponseEntity.ok(ApiResponse.success(leaveService.getLeavesByEmployee(employeeId)));
    }

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<LeaveRequestEntity>>> getPendingLeaves() {
        return ResponseEntity.ok(ApiResponse.success(leaveService.getPendingLeaves()));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<LeaveRequestEntity>> createLeave(@RequestBody LeaveRequestEntity request) {
        LeaveRequestEntity created = leaveService.createLeaveRequest(request);
        return ResponseEntity.ok(ApiResponse.success("Leave request submitted successfully", created));
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<LeaveRequestEntity>> approveLeave(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        String reviewer = body != null ? body.get("reviewer") : "HR Admin";
        String remarks = body != null ? body.get("remarks") : "Approved";
        LeaveRequestEntity approved = leaveService.approveLeave(id, reviewer, remarks);
        return ResponseEntity.ok(ApiResponse.success("Leave request approved", approved));
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<LeaveRequestEntity>> rejectLeave(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        String reviewer = body != null ? body.get("reviewer") : "HR Admin";
        String reason = body != null ? body.get("reason") : "Rejected";
        LeaveRequestEntity rejected = leaveService.rejectLeave(id, reviewer, reason);
        return ResponseEntity.ok(ApiResponse.success("Leave request rejected", rejected));
    }
}
