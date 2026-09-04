package com.freelance.payroll.service;

import com.freelance.payroll.dto.AttendanceRequest;
import com.freelance.payroll.entity.DailyAttendanceEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.SiteEntity;
import com.freelance.payroll.exception.BadRequestException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class AttendanceServiceTest {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private EmployeeService employeeService;

    @Autowired
    private SiteService siteService;

    @Test
    void testCheckInInsideGeofenceAndCheckOut() {
        // Create Site
        SiteEntity site = SiteEntity.builder()
                .code("TEST_SITE_01")
                .name("HQ Test Site")
                .latitude(13.0827)
                .longitude(80.2707)
                .geofenceRadius(200.0)
                .build();
        SiteEntity savedSite = siteService.createSite(site);

        // Create Employee
        EmployeeEntity emp = EmployeeEntity.builder()
                .code("ATT_EMP_01")
                .name("Attendance Tester")
                .email("att.tester@workpulse.com")
                .status("active")
                .build();
        EmployeeEntity savedEmp = employeeService.createEmployee(emp);

        LocalDate testDate = LocalDate.now();
        LocalDateTime inTime = testDate.atTime(9, 0);
        LocalDateTime outTime = testDate.atTime(17, 0);

        // Check in inside geofence (exact same coordinates)
        AttendanceRequest checkInReq = AttendanceRequest.builder()
                .employeeId(savedEmp.getId())
                .siteId(savedSite.getId())
                .latitude(13.0827)
                .longitude(80.2707)
                .timestamp(inTime)
                .build();

        DailyAttendanceEntity inRecord = attendanceService.checkIn(checkInReq);
        assertNotNull(inRecord);
        assertNotNull(inRecord.getFirstPunchTime());

        // Check out 8 hours later
        AttendanceRequest checkOutReq = AttendanceRequest.builder()
                .employeeId(savedEmp.getId())
                .siteId(savedSite.getId())
                .latitude(13.0827)
                .longitude(80.2707)
                .timestamp(outTime)
                .build();

        DailyAttendanceEntity outRecord = attendanceService.checkOut(checkOutReq);
        assertNotNull(outRecord);
        assertNotNull(outRecord.getLastPunchTime());
        assertTrue(outRecord.getWorkingMinutes() >= 470);
    }

    @Test
    void testCheckInOutsideGeofenceThrowsException() {
        SiteEntity site = SiteEntity.builder()
                .code("TEST_SITE_02")
                .name("Geofence Test Site")
                .latitude(13.0827)
                .longitude(80.2707)
                .geofenceRadius(100.0) // 100 meters
                .build();
        SiteEntity savedSite = siteService.createSite(site);

        EmployeeEntity emp = EmployeeEntity.builder()
                .code("ATT_EMP_02")
                .name("Remote Guy")
                .email("remote.guy@workpulse.com")
                .status("active")
                .build();
        EmployeeEntity savedEmp = employeeService.createEmployee(emp);

        // Check in from far away coordinates (Delhi coordinates vs Chennai site)
        AttendanceRequest checkInReq = AttendanceRequest.builder()
                .employeeId(savedEmp.getId())
                .siteId(savedSite.getId())
                .latitude(28.6139)
                .longitude(77.2090)
                .timestamp(LocalDateTime.now())
                .build();

        BadRequestException ex = assertThrows(BadRequestException.class, () -> attendanceService.checkIn(checkInReq));
        assertEquals("Employee is outside the permitted site geofence.", ex.getMessage());
    }
}
