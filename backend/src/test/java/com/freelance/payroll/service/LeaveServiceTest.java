package com.freelance.payroll.service;

import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.LeaveRequestEntity;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class LeaveServiceTest {

    @Autowired
    private LeaveService leaveService;

    @Autowired
    private EmployeeService employeeService;

    @Test
    void testCreateApproveAndRejectLeave() {
        EmployeeEntity emp = EmployeeEntity.builder()
                .code("LV_TEST_01")
                .name("Leave Tester")
                .email("leave.tester@workpulse.com")
                .status("active")
                .build();
        EmployeeEntity savedEmp = employeeService.createEmployee(emp);

        LeaveRequestEntity leave = LeaveRequestEntity.builder()
                .employeeId(savedEmp.getId())
                .leaveType("CASUAL")
                .startDate(LocalDate.now().plusDays(1))
                .endDate(LocalDate.now().plusDays(3))
                .reason("Personal work")
                .build();

        LeaveRequestEntity created = leaveService.createLeaveRequest(leave);
        assertNotNull(created.getId());
        assertEquals("PENDING", created.getStatus());
        assertEquals(3.0, created.getTotalDays());

        LeaveRequestEntity approved = leaveService.approveLeave(created.getId(), "Sarah Jenkins", "Approved by HR");
        assertEquals("APPROVED", approved.getStatus());
        assertEquals("Sarah Jenkins", approved.getApprovedBy());
    }
}
