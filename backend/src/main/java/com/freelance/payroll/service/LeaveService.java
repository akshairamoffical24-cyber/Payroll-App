package com.freelance.payroll.service;

import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.LeaveRequestEntity;
import com.freelance.payroll.entity.NotificationEntity;
import com.freelance.payroll.exception.BadRequestException;
import com.freelance.payroll.exception.ResourceNotFoundException;
import com.freelance.payroll.repository.AuditLogRepository;
import com.freelance.payroll.repository.EmployeeRepository;
import com.freelance.payroll.repository.LeaveRequestRepository;
import com.freelance.payroll.repository.NotificationRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class LeaveService {

    private final LeaveRequestRepository leaveRepository;
    private final EmployeeRepository employeeRepository;
    private final AuditLogRepository auditLogRepository;
    private final NotificationRepository notificationRepository;

    @Autowired
    public LeaveService(
            LeaveRequestRepository leaveRepository,
            EmployeeRepository employeeRepository,
            AuditLogRepository auditLogRepository,
            NotificationRepository notificationRepository) {
        this.leaveRepository = leaveRepository;
        this.employeeRepository = employeeRepository;
        this.auditLogRepository = auditLogRepository;
        this.notificationRepository = notificationRepository;
    }

    public List<LeaveRequestEntity> getAllLeaves() {
        return leaveRepository.findAll();
    }

    public Optional<LeaveRequestEntity> getLeaveById(String id) {
        return leaveRepository.findById(id);
    }

    public List<LeaveRequestEntity> getLeavesByEmployee(String employeeId) {
        return leaveRepository.findByEmployeeIdOrderByCreatedAtDesc(employeeId);
    }

    public List<LeaveRequestEntity> getPendingLeaves() {
        return leaveRepository.findByStatusIgnoreCaseOrderByCreatedAtDesc("PENDING");
    }

    @Transactional
    public LeaveRequestEntity createLeaveRequest(LeaveRequestEntity request) {
        if (request.getEmployeeId() == null || request.getEmployeeId().isBlank()) {
            throw new BadRequestException("Employee ID is required for leave request");
        }
        if (request.getStartDate() == null || request.getEndDate() == null) {
            throw new BadRequestException("Start date and end date are required");
        }
        if (request.getEndDate().isBefore(request.getStartDate())) {
            throw new BadRequestException("End date cannot be before start date");
        }

        EmployeeEntity employee = employeeRepository.findById(request.getEmployeeId())
                .or(() -> employeeRepository.findByCodeIgnoreCase(request.getEmployeeId()))
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + request.getEmployeeId()));

        if (request.getId() == null || request.getId().isBlank()) {
            request.setId("LV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }

        request.setEmployeeId(employee.getId());
        request.setEmployeeCode(employee.getCode());
        request.setEmployeeName(employee.getName());
        request.setDepartment(employee.getDepartment());
        request.setStatus("PENDING");

        long days = ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate()) + 1;
        request.setTotalDays((double) days);

        LeaveRequestEntity saved = leaveRepository.save(request);

        // Notification
        try {
            notificationRepository.save(NotificationEntity.builder()
                    .id("NOTIF-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .title("New Leave Request")
                    .message(employee.getName() + " applied for " + request.getLeaveType() + " leave (" + days + " days)")
                    .type("approval")
                    .category("leave")
                    .actionRoute("/leave-approvals")
                    .timestamp(LocalDateTime.now())
                    .isRead(false)
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public LeaveRequestEntity approveLeave(String id, String reviewerName, String remarks) {
        LeaveRequestEntity leave = leaveRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Leave request not found with id: " + id));

        leave.setStatus("APPROVED");
        leave.setApprovedBy(reviewerName != null ? reviewerName : "HR Manager");
        leave.setReviewedAt(LocalDateTime.now());
        leave.setReviewRemarks(remarks != null ? remarks : "Approved");

        LeaveRequestEntity saved = leaveRepository.save(leave);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("APPROVE_LEAVE")
                    .actorName(reviewerName != null ? reviewerName : "HR")
                    .actorRole("HR")
                    .targetEntity("LEAVE_REQUEST")
                    .details("Approved " + leave.getLeaveType() + " leave for " + leave.getEmployeeName() + " (" + leave.getStartDate() + " to " + leave.getEndDate() + ")")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public LeaveRequestEntity rejectLeave(String id, String reviewerName, String reason) {
        LeaveRequestEntity leave = leaveRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Leave request not found with id: " + id));

        leave.setStatus("REJECTED");
        leave.setApprovedBy(reviewerName != null ? reviewerName : "HR Manager");
        leave.setReviewedAt(LocalDateTime.now());
        leave.setReviewRemarks(reason != null ? reason : "Rejected");

        LeaveRequestEntity saved = leaveRepository.save(leave);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("REJECT_LEAVE")
                    .actorName(reviewerName != null ? reviewerName : "HR")
                    .actorRole("HR")
                    .targetEntity("LEAVE_REQUEST")
                    .details("Rejected leave for " + leave.getEmployeeName() + ". Reason: " + reason)
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }
}
