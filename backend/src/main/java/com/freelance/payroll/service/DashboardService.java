package com.freelance.payroll.service;

import com.freelance.payroll.entity.DailyAttendanceEntity;
import com.freelance.payroll.entity.PayrollRecordEntity;
import com.freelance.payroll.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DashboardService {

    private final EmployeeRepository employeeRepository;
    private final SiteRepository siteRepository;
    private final DailyAttendanceRepository attendanceRepository;
    private final LeaveRequestRepository leaveRepository;
    private final PayrollRecordRepository payrollRepository;

    @Autowired
    public DashboardService(
            EmployeeRepository employeeRepository,
            SiteRepository siteRepository,
            DailyAttendanceRepository attendanceRepository,
            LeaveRequestRepository leaveRepository,
            PayrollRecordRepository payrollRepository) {
        this.employeeRepository = employeeRepository;
        this.siteRepository = siteRepository;
        this.attendanceRepository = attendanceRepository;
        this.leaveRepository = leaveRepository;
        this.payrollRepository = payrollRepository;
    }

    public Map<String, Object> getAdminDashboardMetrics() {
        return computeDashboardStats("ADMIN");
    }

    public Map<String, Object> getHrDashboardMetrics() {
        return computeDashboardStats("HR");
    }

    private Map<String, Object> computeDashboardStats(String role) {
        LocalDate today = LocalDate.now();

        long totalEmployees = employeeRepository.count();
        long activeEmployees = employeeRepository.countByStatusIgnoreCase("active");
        long activeSites = siteRepository.countByStatusIgnoreCase("active");
        long pendingLeaveRequests = leaveRepository.countByStatusIgnoreCase("PENDING");

        List<DailyAttendanceEntity> todayAttendance = attendanceRepository.findByDateOrderByEmployeeIdAsc(today);
        long presentToday = todayAttendance.stream().filter(a -> "present".equalsIgnoreCase(a.getStatus())).count();
        long lateToday = todayAttendance.stream().filter(a -> "late".equalsIgnoreCase(a.getStatus())).count();
        long onLeaveToday = todayAttendance.stream().filter(a -> "leave".equalsIgnoreCase(a.getStatus()) || "on_leave".equalsIgnoreCase(a.getStatus())).count();
        long absentToday = Math.max(0, activeEmployees - (presentToday + lateToday + onLeaveToday));

        // Current month payroll summary
        List<PayrollRecordEntity> currentMonthPayroll = payrollRepository.findByPayrollMonthAndPayrollYearOrderByEmployeeIdAsc(today.getMonthValue(), today.getYear());
        double totalGrossPayroll = currentMonthPayroll.stream().mapToDouble(p -> p.getGrossSalary() != null ? p.getGrossSalary() : 0.0).sum();
        double totalNetPayroll = currentMonthPayroll.stream().mapToDouble(p -> p.getNetSalary() != null ? p.getNetSalary() : 0.0).sum();

        Map<String, Object> stats = new HashMap<>();
        stats.put("role", role);
        stats.put("totalEmployees", totalEmployees);
        stats.put("activeEmployees", activeEmployees);
        stats.put("inactiveEmployees", totalEmployees - activeEmployees);
        stats.put("presentToday", presentToday);
        stats.put("lateToday", lateToday);
        stats.put("absentToday", absentToday);
        stats.put("onLeaveToday", onLeaveToday);
        stats.put("activeSites", activeSites);
        stats.put("pendingLeaveRequests", pendingLeaveRequests);
        stats.put("currentPayrollSummary", Map.of(
                "month", today.getMonthValue(),
                "year", today.getYear(),
                "recordsCount", currentMonthPayroll.size(),
                "totalGrossPayroll", totalGrossPayroll,
                "totalNetPayroll", totalNetPayroll
        ));

        return stats;
    }
}
