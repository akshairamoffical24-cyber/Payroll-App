package com.freelance.payroll.service;

import com.freelance.payroll.entity.PayrollItemEntity;
import com.freelance.payroll.entity.PayrollRecordEntity;
import com.freelance.payroll.repository.PayrollItemRepository;
import com.freelance.payroll.repository.PayrollRecordRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class PayrollService {

    private final PayrollRecordRepository payrollRepository;
    private final PayrollItemRepository payrollItemRepository;
    private final PayrollCalculationService payrollCalculationService;

    @Autowired
    public PayrollService(
            PayrollRecordRepository payrollRepository,
            PayrollItemRepository payrollItemRepository,
            PayrollCalculationService payrollCalculationService) {
        this.payrollRepository = payrollRepository;
        this.payrollItemRepository = payrollItemRepository;
        this.payrollCalculationService = payrollCalculationService;
    }

    public List<PayrollRecordEntity> getAllPayrollRecords() {
        return payrollRepository.findAll();
    }

    public Optional<PayrollRecordEntity> getPayrollRecordById(String id) {
        return payrollRepository.findById(id);
    }

    public List<PayrollRecordEntity> getPayrollRecordsForEmployee(String employeeId) {
        return payrollRepository.findByEmployeeIdOrderByMonthDesc(employeeId);
    }

    public List<PayrollRecordEntity> getPayrollRecordsForMonth(int month, int year) {
        LocalDate monthDate = LocalDate.of(year, month, 1);
        List<PayrollRecordEntity> records = payrollRepository.findByPayrollMonthAndPayrollYearOrderByEmployeeIdAsc(month, year);
        if (records.isEmpty()) {
            records = payrollRepository.findByMonthOrderByEmployeeIdAsc(monthDate);
        }
        return records;
    }

    public List<PayrollItemEntity> getPayrollItems(String payrollId) {
        return payrollItemRepository.findByPayrollId(payrollId);
    }

    public List<PayrollRecordEntity> generatePayroll(int month, int year, String employeeId) {
        return payrollCalculationService.generatePayroll(month, year, employeeId);
    }

    public PayrollRecordEntity updateStatus(String id, String status) {
        PayrollRecordEntity record = payrollRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Payroll record not found"));
        record.setStatus(status);
        return payrollRepository.save(record);
    }
}
