package com.freelance.payroll.service;

import com.freelance.payroll.entity.DailyAttendanceEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.PayrollRecordEntity;
import com.freelance.payroll.repository.DailyAttendanceRepository;
import com.freelance.payroll.repository.EmployeeRepository;
import com.freelance.payroll.repository.PayrollRecordRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class PayrollService {

    private final PayrollRecordRepository payrollRepository;
    private final DailyAttendanceRepository dailyRepository;
    private final EmployeeRepository employeeRepository;

    @Autowired
    public PayrollService(
            PayrollRecordRepository payrollRepository,
            DailyAttendanceRepository dailyRepository,
            EmployeeRepository employeeRepository) {
        this.payrollRepository = payrollRepository;
        this.dailyRepository = dailyRepository;
        this.employeeRepository = employeeRepository;
    }

    public List<PayrollRecordEntity> getPayrollForMonth(LocalDate month) {
        LocalDate startMonth = LocalDate.of(month.getYear(), month.getMonth(), 1);
        List<PayrollRecordEntity> records = payrollRepository.findByMonthOrderByEmployeeIdAsc(startMonth);
        if (records.isEmpty()) {
            return calculateMonthlyPayroll(startMonth);
        }
        return records;
    }

    public List<PayrollRecordEntity> calculateMonthlyPayroll(LocalDate month) {
        LocalDate startMonth = LocalDate.of(month.getYear(), month.getMonth(), 1);
        LocalDate endMonth = startMonth.plusMonths(1).minusDays(1);
        int totalDays = startMonth.lengthOfMonth();

        List<EmployeeEntity> employees = employeeRepository.findAll();
        List<PayrollRecordEntity> records = new ArrayList<>();

        for (EmployeeEntity emp : employees) {
            List<DailyAttendanceEntity> dailyList = dailyRepository.findByEmployeeIdAndDateBetween(emp.getId(), startMonth, endMonth);

            double presentDays = dailyList.stream()
                    .filter(d -> "present".equalsIgnoreCase(d.getStatus()) || "late".equalsIgnoreCase(d.getStatus()) || "onDuty".equalsIgnoreCase(d.getStatus()))
                    .mapToDouble(d -> d.getPayrollWorkingDaysCredit() != null ? d.getPayrollWorkingDaysCredit() : 1.0)
                    .sum();

            double halfDays = dailyList.stream().filter(d -> "halfDay".equalsIgnoreCase(d.getStatus())).count() * 0.5;
            double weeklyOffs = 4.0;
            double holidays = 1.0;
            double paidLeaves = 1.0;
            double payableDays = presentDays + halfDays + weeklyOffs + holidays + paidLeaves;
            if (payableDays > totalDays) payableDays = totalDays;

            double gross = emp.getMonthlyCtc() != null ? emp.getMonthlyCtc() : 35000.0;
            double perDay = gross / totalDays;
            double calculatedPayable = Math.round(perDay * payableDays);
            double deductions = 200.0; // Professional tax
            double net = calculatedPayable - deductions;

            PayrollRecordEntity record = payrollRepository.findByEmployeeIdAndMonth(emp.getId(), startMonth)
                    .orElse(PayrollRecordEntity.builder()
                            .id("PAY-" + startMonth.getYear() + "-" + startMonth.getMonthValue() + "-" + emp.getId())
                            .employeeId(emp.getId())
                            .month(startMonth)
                            .build());

            record.setTotalDaysInMonth(totalDays);
            record.setPayableDays(payableDays);
            record.setPresentDays(presentDays);
            record.setWeeklyOffs(weeklyOffs);
            record.setHolidays(holidays);
            record.setPaidLeaves(paidLeaves);
            record.setAbsentDays((double) (totalDays - payableDays));
            record.setHalfDays(halfDays);
            record.setGrossMonthlyCtc(gross);
            record.setPerDaySalary(perDay);
            record.setCalculatedPayableSalary(calculatedPayable);
            record.setDeductions(deductions);
            record.setNetPayableSalary(net);
            record.setStatus("calculated");

            records.add(payrollRepository.save(record));
        }

        return records;
    }

    public PayrollRecordEntity updateStatus(String id, String status) {
        Optional<PayrollRecordEntity> recordOpt = payrollRepository.findById(id);
        if (recordOpt.isPresent()) {
            PayrollRecordEntity record = recordOpt.get();
            record.setStatus(status);
            return payrollRepository.save(record);
        }
        return null;
    }
}
