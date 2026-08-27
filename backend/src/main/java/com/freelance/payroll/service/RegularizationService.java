package com.freelance.payroll.service;

import com.freelance.payroll.dto.RegularizationReviewRequest;
import com.freelance.payroll.dto.RegularizationSubmissionRequest;
import com.freelance.payroll.entity.DailyAttendanceEntity;
import com.freelance.payroll.entity.RegularizationRequestEntity;
import com.freelance.payroll.repository.DailyAttendanceRepository;
import com.freelance.payroll.repository.RegularizationRequestRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class RegularizationService {

    private final RegularizationRequestRepository regularizationRepository;
    private final DailyAttendanceRepository dailyAttendanceRepository;

    @Autowired
    public RegularizationService(
            RegularizationRequestRepository regularizationRepository,
            DailyAttendanceRepository dailyAttendanceRepository) {
        this.regularizationRepository = regularizationRepository;
        this.dailyAttendanceRepository = dailyAttendanceRepository;
    }

    public List<RegularizationRequestEntity> getAllRequests() {
        return regularizationRepository.findAllByOrderByAppliedAtDesc();
    }

    public List<RegularizationRequestEntity> getRequestsForEmployee(String employeeId) {
        return regularizationRepository.findByEmployeeIdOrderByAppliedAtDesc(employeeId);
    }

    public RegularizationRequestEntity submitRequest(RegularizationSubmissionRequest req) {
        RegularizationRequestEntity entity = RegularizationRequestEntity.builder()
                .id("REG-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .employeeId(req.getEmployeeId())
                .employeeCode(req.getEmployeeCode())
                .employeeName(req.getEmployeeName())
                .department(req.getDepartment())
                .requestType(req.getRequestType())
                .reasonCategory(req.getReasonCategory())
                .attendanceDate(req.getAttendanceDate())
                .requestedInTime(req.getRequestedInTime())
                .requestedOutTime(req.getRequestedOutTime())
                .remarks(req.getRemarks())
                .appliedAt(LocalDateTime.now())
                .status("pending")
                .build();

        return regularizationRepository.save(entity);
    }

    public RegularizationRequestEntity reviewRequest(String id, RegularizationReviewRequest review) {
        Optional<RegularizationRequestEntity> opt = regularizationRepository.findById(id);
        if (opt.isEmpty()) return null;

        RegularizationRequestEntity entity = opt.get();
        entity.setStatus(review.getStatus());
        entity.setReviewedBy(review.getReviewedBy() != null ? review.getReviewedBy() : "Admin/HR");
        entity.setReviewedAt(LocalDateTime.now());
        entity.setReviewComments(review.getReviewComments());
        entity = regularizationRepository.save(entity);

        // If approved, update the corresponding daily attendance record
        if ("approved".equalsIgnoreCase(review.getStatus())) {
            Optional<DailyAttendanceEntity> dailyOpt = dailyAttendanceRepository
                    .findByEmployeeIdAndDate(entity.getEmployeeId(), entity.getAttendanceDate());

            DailyAttendanceEntity daily = dailyOpt.orElse(DailyAttendanceEntity.builder()
                    .id("ATT-" + entity.getAttendanceDate() + "-" + entity.getEmployeeId())
                    .employeeId(entity.getEmployeeId())
                    .date(entity.getAttendanceDate())
                    .build());

            daily.setStatus("present");
            daily.setSourceType("regularized");
            daily.setRemarks("Regularized by " + entity.getReviewedBy() + ": " + entity.getRemarks());
            daily.setPayrollWorkingDaysCredit(1.0);
            dailyAttendanceRepository.save(daily);
        }

        return entity;
    }
}
