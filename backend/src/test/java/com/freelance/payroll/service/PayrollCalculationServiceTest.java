package com.freelance.payroll.service;

import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.PayrollRecordEntity;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class PayrollCalculationServiceTest {

    @Autowired
    private PayrollCalculationService payrollCalculationService;

    @Autowired
    private EmployeeService employeeService;

    @Test
    void testPayrollCalculation() {
        EmployeeEntity emp = EmployeeEntity.builder()
                .code("PAY_TEST_01")
                .name("Payroll Employee")
                .email("payroll.emp@workpulse.com")
                .monthlyCtc(60000.0)
                .basicSalary(30000.0)
                .epfEnabled(true)
                .professionalTaxEnabled(true)
                .status("active")
                .build();
        EmployeeEntity saved = employeeService.createEmployee(emp);

        int month = LocalDate.now().getMonthValue();
        int year = LocalDate.now().getYear();

        List<PayrollRecordEntity> records = payrollCalculationService.generatePayroll(month, year, saved.getId());
        assertFalse(records.isEmpty());

        PayrollRecordEntity record = records.get(0);
        assertEquals(saved.getId(), record.getEmployeeId());
        assertNotNull(record.getGrossSalary());
        assertNotNull(record.getNetSalary());
        assertNotNull(record.getDeductions());
        assertTrue(record.getGrossSalary() > 0);
        assertTrue(record.getNetSalary() > 0);
        assertEquals(record.getGrossSalary() - record.getDeductions(), record.getNetSalary(), 0.01);
    }
}
