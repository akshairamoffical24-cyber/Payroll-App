package com.freelance.payroll.service;

import com.freelance.payroll.dto.BiometricPunchRequest;
import com.freelance.payroll.entity.AttendancePunchEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.repository.AttendancePunchRepository;
import com.freelance.payroll.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class BiometricService {

    private final AttendancePunchRepository punchRepository;
    private final EmployeeRepository employeeRepository;
    private final AttendanceService attendanceService;

    @Autowired
    public BiometricService(
            AttendancePunchRepository punchRepository,
            EmployeeRepository employeeRepository,
            AttendanceService attendanceService) {
        this.punchRepository = punchRepository;
        this.employeeRepository = employeeRepository;
        this.attendanceService = attendanceService;
    }

    public void ingestBiometricPunch(BiometricPunchRequest request) {
        Optional<EmployeeEntity> empOpt = employeeRepository.findByCodeIgnoreCase(request.getEmployeeCode());
        if (empOpt.isEmpty()) {
            return;
        }

        EmployeeEntity employee = empOpt.get();
        LocalDateTime timestamp = request.getTimestamp() != null ? request.getTimestamp() : LocalDateTime.now();
        String punchType = timestamp.getHour() < 13 ? "inPunch" : "outPunch";

        AttendancePunchEntity punch = AttendancePunchEntity.builder()
                .id("PUNCH-BIO-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .employeeId(employee.getId())
                .timestamp(timestamp)
                .type(punchType)
                .source("biometric")
                .siteName(request.getTerminalLocation() != null ? request.getTerminalLocation() : "HQ Main Terminal")
                .isVerified(true)
                .isPendingSync(false)
                .build();

        punchRepository.save(punch);
        attendanceService.recalculateDailyAttendance(employee.getId(), timestamp.toLocalDate());
    }
}
