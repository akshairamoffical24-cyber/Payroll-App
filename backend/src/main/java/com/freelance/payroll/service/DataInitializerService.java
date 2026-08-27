package com.freelance.payroll.service;

import com.freelance.payroll.entity.*;
import com.freelance.payroll.repository.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.Arrays;

@Slf4j
@Service
public class DataInitializerService implements CommandLineRunner {

    private final UserRepository userRepository;
    private final EmployeeRepository employeeRepository;
    private final SiteRepository siteRepository;
    private final EmployeeSiteMappingRepository mappingRepository;
    private final AttendancePunchRepository punchRepository;
    private final DailyAttendanceRepository dailyRepository;
    private final RegularizationRequestRepository regularizationRepository;
    private final NotificationRepository notificationRepository;
    private final AuditLogRepository auditLogRepository;
    private final SystemSettingsRepository settingsRepository;

    @org.springframework.beans.factory.annotation.Autowired
    public DataInitializerService(
            UserRepository userRepository,
            EmployeeRepository employeeRepository,
            SiteRepository siteRepository,
            EmployeeSiteMappingRepository mappingRepository,
            AttendancePunchRepository punchRepository,
            DailyAttendanceRepository dailyRepository,
            RegularizationRequestRepository regularizationRepository,
            NotificationRepository notificationRepository,
            AuditLogRepository auditLogRepository,
            SystemSettingsRepository settingsRepository) {
        this.userRepository = userRepository;
        this.employeeRepository = employeeRepository;
        this.siteRepository = siteRepository;
        this.mappingRepository = mappingRepository;
        this.punchRepository = punchRepository;
        this.dailyRepository = dailyRepository;
        this.regularizationRepository = regularizationRepository;
        this.notificationRepository = notificationRepository;
        this.auditLogRepository = auditLogRepository;
        this.settingsRepository = settingsRepository;
    }

    @Override
    public void run(String... args) {
        log.info("Checking database and initializing WorkPulse Payroll & Attendance seed data...");

        // 1. Seed Users
        if (userRepository.count() == 0) {
            userRepository.saveAll(Arrays.asList(
                    UserEntity.builder()
                            .id("USER-001")
                            .email("admin@workpulse.com")
                            .password("admin123")
                            .name("Alexander Wright")
                            .role("admin")
                            .token("JWT-ADMIN-001")
                            .build(),
                    UserEntity.builder()
                            .id("USER-002")
                            .email("hr@workpulse.com")
                            .password("hr123")
                            .name("Sarah Jenkins")
                            .role("hr")
                            .token("JWT-HR-002")
                            .build(),
                    UserEntity.builder()
                            .id("USER-003")
                            .email("field@workpulse.com")
                            .password("field123")
                            .name("Rajesh Kumar")
                            .role("fieldStaff")
                            .employeeId("EMP-001")
                            .token("JWT-FIELD-003")
                            .build(),
                    UserEntity.builder()
                            .id("USER-048")
                            .email("pk.kumar90543@gmail.com")
                            .password("field123")
                            .name("Praveen Kumar")
                            .role("fieldStaff")
                            .employeeId("EMP-048")
                            .token("JWT-FIELD-048")
                            .build()
            ));
        }

        // Clear legacy dummy employee & attendance records so only user-created and Excel-imported data exists
        employeeRepository.deleteAll();
        mappingRepository.deleteAll();
        punchRepository.deleteAll();
        dailyRepository.deleteAll();
        regularizationRepository.deleteAll();

        // 3. Seed Master Sites
        if (siteRepository.count() == 0) {
            siteRepository.saveAll(Arrays.asList(
                    SiteEntity.builder()
                            .id("SITE-001")
                            .code("SITE001")
                            .name("CTS Chennai Campus")
                            .client("Cognizant Tech Solutions")
                            .project("Project Sirius OMR")
                            .address("Plot 1/C1, SIPCOT IT Park, Siruseri, Chennai - 603103")
                            .latitude(12.9010)
                            .longitude(80.2279)
                            .geofenceRadius(200.0)
                            .poNumber("PO-2026-CTS-091")
                            .siteManagerName("Muruganandham S.")
                            .siteEngineerName("Operations Lead")
                            .status("active")
                            .build(),
                    SiteEntity.builder()
                            .id("SITE-002")
                            .code("SITE002")
                            .name("Wipro Chennai SEZ")
                            .client("Wipro Technologies")
                            .project("Project Falcon Phase 2")
                            .address("ELCOT SEZ, Sholinganallur, Chennai - 600119")
                            .latitude(12.9035)
                            .longitude(80.2295)
                            .geofenceRadius(500.0)
                            .poNumber("PO-2026-WIP-104")
                            .siteManagerName("Karthik Narayanan")
                            .siteEngineerName("Operations Lead")
                            .status("active")
                            .build(),
                    SiteEntity.builder()
                            .id("SITE-003")
                            .code("SITE003")
                            .name("WTC Chennai Perungudi")
                            .client("Brigade Enterprises")
                            .project("World Trade Center Towers")
                            .address("142 Rajiv Gandhi Salai, Perungudi, Chennai - 600096")
                            .latitude(12.9698)
                            .longitude(80.2442)
                            .geofenceRadius(700.0)
                            .poNumber("PO-2026-WTC-440")
                            .siteManagerName("Arvind Swamy")
                            .siteEngineerName("Operations Lead")
                            .status("active")
                            .build(),
                    SiteEntity.builder()
                            .id("SITE-004")
                            .code("SITE004")
                            .name("Coimbatore IT Park Project")
                            .client("ELCOT Tamil Nadu")
                            .project("TIDEL Park Extension")
                            .address("Vilankurichi Road, Civil Aerodrome Post, Coimbatore - 641014")
                            .latitude(11.0168)
                            .longitude(76.9558)
                            .geofenceRadius(1000.0)
                            .poNumber("PO-2026-CBE-812")
                            .siteManagerName("Gopalakrishnan V.")
                            .siteEngineerName("Operations Lead")
                            .status("active")
                            .build(),
                    SiteEntity.builder()
                            .id("SITE-005")
                            .code("SITE005")
                            .name("Client ABC Infra Site")
                            .client("ABC Infrastructure Ltd")
                            .project("Metro Line Expansion")
                            .address("100 Feet Road, Indiranagar, Bengaluru - 560038")
                            .latitude(12.9716)
                            .longitude(77.5946)
                            .geofenceRadius(200.0)
                            .poNumber("PO-2026-ABC-319")
                            .siteManagerName("Prakash Rao")
                            .siteEngineerName("Operations Lead")
                            .status("active")
                            .build()
            ));
        }

        // 7. Seed Notifications
        if (notificationRepository.count() == 0) {
            notificationRepository.save(
                    NotificationEntity.builder()
                            .id("NOTIF-001")
                            .title("System Ready")
                            .message("Spring Boot REST Backend is initialized and connected to H2 database.")
                            .timestamp(LocalDateTime.now())
                            .type("info")
                            .category("general")
                            .isRead(false)
                            .build()
            );
        }

        // 8. Seed System Settings
        if (settingsRepository.count() == 0) {
            settingsRepository.save(
                    SystemSettingsEntity.builder()
                            .id("SYS-SETTINGS-001")
                            .companyName("WorkPulse Enterprise Technologies Ltd.")
                            .officeStartTime("09:00 AM")
                            .officeEndTime("06:00 PM")
                            .lateGraceMinutes(30)
                            .halfDayThresholdHours(4)
                            .defaultGeofenceRadiusMeters(200.0)
                            .enableAutoPayroll(true)
                            .enableBiometricSync(true)
                            .allowOfflinePunches(true)
                            .maxGpsAccuracyThresholdMeters(50.0)
                            .build()
            );
        }

        // 9. Seed Audit Logs
        if (auditLogRepository.count() == 0) {
            auditLogRepository.save(
                    AuditLogEntity.builder()
                            .id("AUDIT-001")
                            .action("SYSTEM_INITIALIZED")
                            .actorName("System Security Engine")
                            .actorRole("Automated Rule Guard")
                            .details("Spring Boot REST Backend with H2 embedded database initialized successfully.")
                            .timestamp(LocalDateTime.now())
                            .targetEntity("SYSTEM")
                            .build()
            );
        }

        log.info("WorkPulse database seeding complete!");
    }
}
