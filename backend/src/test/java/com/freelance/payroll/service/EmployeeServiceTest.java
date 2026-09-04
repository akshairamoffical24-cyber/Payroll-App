package com.freelance.payroll.service;

import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.exception.BadRequestException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class EmployeeServiceTest {

    @Autowired
    private EmployeeService employeeService;

    @Test
    void testCreateAndGetEmployee() {
        EmployeeEntity emp = EmployeeEntity.builder()
                .code("EMP999")
                .name("Test Employee")
                .email("test.emp@workpulse.com")
                .department("Engineering")
                .designation("Software Engineer")
                .type("office")
                .status("active")
                .joiningDate(LocalDate.now())
                .monthlyCtc(50000.0)
                .basicSalary(25000.0)
                .build();

        EmployeeEntity created = employeeService.createEmployee(emp);
        assertNotNull(created.getId());
        assertEquals("EMP999", created.getCode());

        Optional<EmployeeEntity> fetched = employeeService.getEmployeeById(created.getId());
        assertTrue(fetched.isPresent());
        assertEquals("Test Employee", fetched.get().getName());

        List<EmployeeEntity> searchResults = employeeService.searchEmployees("Test");
        assertFalse(searchResults.isEmpty());
    }

    @Test
    void testDuplicateEmployeeCodeThrowsException() {
        EmployeeEntity emp1 = EmployeeEntity.builder()
                .code("DUP001")
                .name("First Employee")
                .email("first@workpulse.com")
                .build();
        employeeService.createEmployee(emp1);

        EmployeeEntity emp2 = EmployeeEntity.builder()
                .code("DUP001")
                .name("Second Employee")
                .email("second@workpulse.com")
                .build();

        assertThrows(BadRequestException.class, () -> employeeService.createEmployee(emp2));
    }

    @Test
    void testExportEmployeesToExcel() {
        byte[] excelBytes = employeeService.exportEmployeesToExcel();
        assertNotNull(excelBytes);
        assertTrue(excelBytes.length > 0);
    }
}
