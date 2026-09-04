package com.freelance.payroll.service;

import com.freelance.payroll.entity.*;
import com.freelance.payroll.exception.ResourceNotFoundException;
import com.freelance.payroll.repository.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.*;

@Slf4j
@Service
public class PayrollCalculationService {

    private final EmployeeRepository employeeRepository;
    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final PayrollRecordRepository payrollRecordRepository;
    private final PayrollItemRepository payrollItemRepository;
    private final AuditLogRepository auditLogRepository;

    @Autowired
    public PayrollCalculationService(
            EmployeeRepository employeeRepository,
            DailyAttendanceRepository dailyAttendanceRepository,
            PayrollRecordRepository payrollRecordRepository,
            PayrollItemRepository payrollItemRepository,
            AuditLogRepository auditLogRepository) {
        this.employeeRepository = employeeRepository;
        this.dailyAttendanceRepository = dailyAttendanceRepository;
        this.payrollRecordRepository = payrollRecordRepository;
        this.payrollItemRepository = payrollItemRepository;
        this.auditLogRepository = auditLogRepository;
    }

    @Transactional
    public List<PayrollRecordEntity> generatePayroll(int month, int year, String specificEmployeeId) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate monthStart = yearMonth.atDay(1);
        LocalDate monthEnd = yearMonth.atEndOfMonth();
        int totalDaysInMonth = yearMonth.lengthOfMonth();

        List<EmployeeEntity> employees;
        if (specificEmployeeId != null && !specificEmployeeId.isBlank()) {
            EmployeeEntity emp = employeeRepository.findById(specificEmployeeId)
                    .or(() -> employeeRepository.findByCodeIgnoreCase(specificEmployeeId))
                    .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + specificEmployeeId));
            employees = Collections.singletonList(emp);
        } else {
            employees = employeeRepository.findByStatusIgnoreCase("active");
            if (employees.isEmpty()) {
                employees = employeeRepository.findAll();
            }
        }

        List<PayrollRecordEntity> generated = new ArrayList<>();

        for (EmployeeEntity emp : employees) {
            PayrollRecordEntity record = calculateSingleEmployeePayroll(emp, yearMonth, monthStart, monthEnd, totalDaysInMonth);
            generated.add(record);
        }

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("GENERATE_PAYROLL")
                    .actorName("HR/Admin")
                    .actorRole("HR")
                    .targetEntity("PAYROLL")
                    .details("Generated payroll for " + generated.size() + " employees for month " + month + "/" + year)
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return generated;
    }

    private PayrollRecordEntity calculateSingleEmployeePayroll(
            EmployeeEntity emp, YearMonth yearMonth, LocalDate monthStart, LocalDate monthEnd, int totalDaysInMonth) {

        List<DailyAttendanceEntity> attendanceRecords = dailyAttendanceRepository.findByEmployeeIdAndDateBetween(
                emp.getId(), monthStart, monthEnd
        );

        double presentDays = 0.0;
        double halfDays = 0.0;
        double absentDays = 0.0;
        double paidLeaves = 0.0;
        double weeklyOffs = 4.0; // Standard 4 Sundays
        double holidays = 1.0;

        for (DailyAttendanceEntity att : attendanceRecords) {
            String status = att.getStatus() != null ? att.getStatus().toLowerCase() : "";
            switch (status) {
                case "present", "late" -> presentDays += 1.0;
                case "halfday" -> halfDays += 1.0;
                case "absent", "missingin", "missingout" -> absentDays += 1.0;
                case "leave", "on_leave", "paidleave" -> paidLeaves += 1.0;
                case "weeklyoff" -> weeklyOffs += 1.0;
                case "holiday" -> holidays += 1.0;
                default -> presentDays += 1.0;
            }
        }

        // If no attendance was logged yet, default to full present days for calculation preview
        if (attendanceRecords.isEmpty()) {
            presentDays = Math.max(0, totalDaysInMonth - weeklyOffs - holidays);
        }

        double payableDays = presentDays + (halfDays * 0.5) + paidLeaves + weeklyOffs + holidays;
        payableDays = Math.min(totalDaysInMonth, payableDays);

        double monthlyCtc = emp.getMonthlyCtc() != null && emp.getMonthlyCtc() > 0 ? emp.getMonthlyCtc() : 30000.0;
        BigDecimal monthlyCtcBd = BigDecimal.valueOf(monthlyCtc);
        BigDecimal perDaySalary = monthlyCtcBd.divide(BigDecimal.valueOf(totalDaysInMonth), 2, RoundingMode.HALF_UP);

        BigDecimal grossCalculated = perDaySalary.multiply(BigDecimal.valueOf(payableDays)).setScale(2, RoundingMode.HALF_UP);

        // Calculate itemized earnings & deductions
        BigDecimal basicSalary = grossCalculated.multiply(BigDecimal.valueOf(0.50)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal hra = grossCalculated.multiply(BigDecimal.valueOf(0.20)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal specialAllowance = grossCalculated.subtract(basicSalary).subtract(hra).setScale(2, RoundingMode.HALF_UP);

        // Deductions
        BigDecimal pfDeduction = Boolean.TRUE.equals(emp.getEpfEnabled()) ? basicSalary.multiply(BigDecimal.valueOf(0.12)).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        BigDecimal esiDeduction = Boolean.TRUE.equals(emp.getEsiEnabled()) ? grossCalculated.multiply(BigDecimal.valueOf(0.0075)).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        BigDecimal profTax = Boolean.TRUE.equals(emp.getProfessionalTaxEnabled()) ? BigDecimal.valueOf(200.00) : BigDecimal.ZERO;

        BigDecimal totalDeductions = pfDeduction.add(esiDeduction).add(profTax).setScale(2, RoundingMode.HALF_UP);
        BigDecimal netPayable = grossCalculated.subtract(totalDeductions).setScale(2, RoundingMode.HALF_UP);

        // Find or create payroll record
        Optional<PayrollRecordEntity> existingRecordOpt = payrollRecordRepository.findByEmployeeIdAndPayrollMonthAndPayrollYear(
                emp.getId(), yearMonth.getMonthValue(), yearMonth.getYear()
        );

        PayrollRecordEntity record = existingRecordOpt.orElse(PayrollRecordEntity.builder()
                .id("PAY-" + yearMonth.getYear() + String.format("%02d", yearMonth.getMonthValue()) + "-" + emp.getId())
                .employeeId(emp.getId())
                .payrollMonth(yearMonth.getMonthValue())
                .payrollYear(yearMonth.getYear())
                .month(monthStart)
                .build());

        record.setEmployeeCode(emp.getCode());
        record.setEmployeeName(emp.getName());
        record.setDepartment(emp.getDepartment());
        record.setTotalDaysInMonth(totalDaysInMonth);
        record.setWorkingDays((double) totalDaysInMonth);
        record.setPayableDays(payableDays);
        record.setPresentDays(presentDays);
        record.setHalfDays(halfDays);
        record.setAbsentDays(absentDays);
        record.setLeaveDays(paidLeaves);
        record.setPaidLeaves(paidLeaves);
        record.setWeeklyOffs(weeklyOffs);
        record.setHolidays(holidays);
        record.setGrossMonthlyCtc(monthlyCtc);
        record.setPerDaySalary(perDaySalary.doubleValue());
        record.setGrossSalary(grossCalculated.doubleValue());
        record.setCalculatedPayableSalary(grossCalculated.doubleValue());
        record.setBasicSalary(basicSalary.doubleValue());
        record.setDeductions(totalDeductions.doubleValue());
        record.setNetSalary(netPayable.doubleValue());
        record.setNetPayableSalary(netPayable.doubleValue());
        record.setStatus("calculated");

        PayrollRecordEntity savedRecord = payrollRecordRepository.save(record);

        // Save itemized payroll items
        payrollItemRepository.deleteByPayrollId(savedRecord.getId());
        List<PayrollItemEntity> items = Arrays.asList(
                PayrollItemEntity.builder().id("ITEM-" + UUID.randomUUID().toString().substring(0, 8)).payrollId(savedRecord.getId()).itemName("Basic Salary").itemType("EARNING").amount(basicSalary).build(),
                PayrollItemEntity.builder().id("ITEM-" + UUID.randomUUID().toString().substring(0, 8)).payrollId(savedRecord.getId()).itemName("House Rent Allowance (HRA)").itemType("EARNING").amount(hra).build(),
                PayrollItemEntity.builder().id("ITEM-" + UUID.randomUUID().toString().substring(0, 8)).payrollId(savedRecord.getId()).itemName("Special Allowance").itemType("EARNING").amount(specialAllowance).build(),
                PayrollItemEntity.builder().id("ITEM-" + UUID.randomUUID().toString().substring(0, 8)).payrollId(savedRecord.getId()).itemName("Provident Fund (PF)").itemType("DEDUCTION").amount(pfDeduction).build(),
                PayrollItemEntity.builder().id("ITEM-" + UUID.randomUUID().toString().substring(0, 8)).payrollId(savedRecord.getId()).itemName("Employee State Insurance (ESI)").itemType("DEDUCTION").amount(esiDeduction).build(),
                PayrollItemEntity.builder().id("ITEM-" + UUID.randomUUID().toString().substring(0, 8)).payrollId(savedRecord.getId()).itemName("Professional Tax").itemType("DEDUCTION").amount(profTax).build()
        );
        payrollItemRepository.saveAll(items);

        return savedRecord;
    }
}
