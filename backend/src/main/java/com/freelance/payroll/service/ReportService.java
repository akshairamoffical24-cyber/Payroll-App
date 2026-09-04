package com.freelance.payroll.service;

import com.freelance.payroll.entity.*;
import com.freelance.payroll.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReportService {

    private final DailyAttendanceRepository attendanceRepository;
    private final PayrollRecordRepository payrollRepository;
    private final EmployeeRepository employeeRepository;
    private final LeaveRequestRepository leaveRepository;

    @Autowired
    public ReportService(
            DailyAttendanceRepository attendanceRepository,
            PayrollRecordRepository payrollRepository,
            EmployeeRepository employeeRepository,
            LeaveRequestRepository leaveRepository) {
        this.attendanceRepository = attendanceRepository;
        this.payrollRepository = payrollRepository;
        this.employeeRepository = employeeRepository;
        this.leaveRepository = leaveRepository;
    }

    public Map<String, Object> getAttendanceReport(LocalDate from, LocalDate to) {
        LocalDate start = from != null ? from : LocalDate.now().minusDays(30);
        LocalDate end = to != null ? to : LocalDate.now();
        List<DailyAttendanceEntity> records = attendanceRepository.findByDateBetween(start, end);

        Map<String, Object> report = new HashMap<>();
        report.put("fromDate", start);
        report.put("toDate", end);
        report.put("totalRecords", records.size());
        report.put("records", records);
        return report;
    }

    public Map<String, Object> getPayrollReport(Integer month, Integer year) {
        int m = month != null ? month : LocalDate.now().getMonthValue();
        int y = year != null ? year : LocalDate.now().getYear();

        List<PayrollRecordEntity> records = payrollRepository.findByPayrollMonthAndPayrollYearOrderByEmployeeIdAsc(m, y);
        double totalGross = records.stream().mapToDouble(r -> r.getGrossSalary() != null ? r.getGrossSalary() : 0.0).sum();
        double totalNet = records.stream().mapToDouble(r -> r.getNetSalary() != null ? r.getNetSalary() : 0.0).sum();
        double totalDeductions = records.stream().mapToDouble(r -> r.getDeductions() != null ? r.getDeductions() : 0.0).sum();

        Map<String, Object> report = new HashMap<>();
        report.put("month", m);
        report.put("year", y);
        report.put("totalEmployees", records.size());
        report.put("totalGrossSalary", totalGross);
        report.put("totalDeductions", totalDeductions);
        report.put("totalNetSalary", totalNet);
        report.put("records", records);
        return report;
    }

    public Map<String, Object> getEmployeeReport(String department) {
        List<EmployeeEntity> employees;
        if (department != null && !department.isBlank()) {
            employees = employeeRepository.findByDepartmentIgnoreCase(department);
        } else {
            employees = employeeRepository.findAll();
        }

        Map<String, Object> report = new HashMap<>();
        report.put("department", department != null ? department : "ALL");
        report.put("totalEmployees", employees.size());
        report.put("activeEmployees", employees.stream().filter(e -> "active".equalsIgnoreCase(e.getStatus())).count());
        report.put("employees", employees);
        return report;
    }

    public Map<String, Object> getLeaveReport(LocalDate from, LocalDate to) {
        List<LeaveRequestEntity> leaves = leaveRepository.findAll();
        Map<String, Object> report = new HashMap<>();
        report.put("totalLeaves", leaves.size());
        report.put("pendingLeaves", leaves.stream().filter(l -> "PENDING".equalsIgnoreCase(l.getStatus())).count());
        report.put("approvedLeaves", leaves.stream().filter(l -> "APPROVED".equalsIgnoreCase(l.getStatus())).count());
        report.put("rejectedLeaves", leaves.stream().filter(l -> "REJECTED".equalsIgnoreCase(l.getStatus())).count());
        report.put("leaves", leaves);
        return report;
    }
}
