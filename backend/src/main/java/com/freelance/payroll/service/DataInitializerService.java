package com.freelance.payroll.service;

import com.freelance.payroll.entity.*;
import com.freelance.payroll.repository.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Arrays;

@Slf4j
@Service
public class DataInitializerService implements CommandLineRunner {

    private final UserRepository userRepository;
    private final SiteRepository siteRepository;
    private final AuditLogRepository auditLogRepository;
    private final SystemSettingsRepository settingsRepository;
    private final PasswordEncoder passwordEncoder;
    private final JdbcTemplate jdbcTemplate;

    @Autowired
    public DataInitializerService(
            UserRepository userRepository,
            SiteRepository siteRepository,
            AuditLogRepository auditLogRepository,
            SystemSettingsRepository settingsRepository,
            PasswordEncoder passwordEncoder,
            JdbcTemplate jdbcTemplate) {
        this.userRepository = userRepository;
        this.siteRepository = siteRepository;
        this.auditLogRepository = auditLogRepository;
        this.settingsRepository = settingsRepository;
        this.passwordEncoder = passwordEncoder;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        log.info("Checking initial system seed data and ensuring table schemas...");

        // Ensure columns in PostgreSQL users table if upgrading from older schema
        try {
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(255)");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS token VARCHAR(512)");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS google_subject_id VARCHAR(255)");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id VARCHAR(255)");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(512)");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS department VARCHAR(255)");
            jdbcTemplate.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50) DEFAULT 'LOCAL'");
        } catch (Exception e) {
            log.warn("Database schema auto-alignment notice: {}", e.getMessage());
        }

        // 1. Seed Default Administrative and Staff Users if not present
        try {
            if (userRepository.count() == 0) {
                log.info("Seeding default administrative users with BCrypt encryption...");

                UserEntity admin = UserEntity.builder()
                        .id("USER-001")
                        .username("admin")
                        .email("admin@workpulse.com")
                        .password(passwordEncoder.encode("admin123"))
                        .name("Alexander Wright")
                        .role("ADMIN")
                        .department("Executive Leadership")
                        .active(true)
                        .employeeId("EMP-001")
                        .build();

                UserEntity hr = UserEntity.builder()
                        .id("USER-002")
                        .username("hr")
                        .email("hr@workpulse.com")
                        .password(passwordEncoder.encode("hr123"))
                        .name("Sarah Jenkins")
                        .role("HR")
                        .department("People Operations")
                        .active(true)
                        .employeeId("EMP-002")
                        .build();

                UserEntity field = UserEntity.builder()
                        .id("USER-003")
                        .username("field")
                        .email("field@workpulse.com")
                        .password(passwordEncoder.encode("field123"))
                        .name("Rajesh Kumar")
                        .role("FIELD_STAFF")
                        .department("Civil Infrastructure")
                        .active(true)
                        .employeeId("EMP-003")
                        .build();

                userRepository.saveAll(Arrays.asList(admin, hr, field));
                log.info("Default user accounts successfully seeded.");
            } else {
                // Update passwords to BCrypt if needed
                userRepository.findAll().forEach(user -> {
                    if (user.getPassword() != null && !user.getPassword().startsWith("$2a$") && !user.getPassword().startsWith("$2b$")) {
                        user.setPassword(passwordEncoder.encode(user.getPassword()));
                        userRepository.save(user);
                    }
                });
            }
        } catch (Exception e) {
            log.warn("User seeding check warning: {}", e.getMessage());
        }

        // 2. Seed Default Sites
        if (siteRepository.count() == 0) {
            siteRepository.saveAll(Arrays.asList(
                    SiteEntity.builder()
                            .id("SITE-001")
                            .code("HQ-CH-01")
                            .name("Corporate Headquarters")
                            .client("WorkPulse Technologies Ltd.")
                            .project("Corporate Tower Operations")
                            .address("Block 4, Olympia Tech Park, Guindy, Chennai - 600032")
                            .latitude(13.0118)
                            .longitude(80.2038)
                            .geofenceRadius(500.0)
                            .poNumber("PO-2026-HQ-001")
                            .siteManagerName("Karthik Raman")
                            .siteEngineerName("Priya Sharma")
                            .status("active")
                            .build(),
                    SiteEntity.builder()
                            .id("SITE-002")
                            .code("OMR-IT-02")
                            .name("OMR IT Expressway Campus")
                            .client("Nexus Cloud Infrastructure")
                            .project("Cloud Data Center Build")
                            .address("Siruseri IT Park, OMR, Chennai - 603103")
                            .latitude(12.8258)
                            .longitude(80.2195)
                            .geofenceRadius(600.0)
                            .poNumber("PO-2026-OMR-102")
                            .siteManagerName("Dinesh Kumar")
                            .siteEngineerName("Ravi Chandran")
                            .status("active")
                            .build(),
                    SiteEntity.builder()
                            .id("SITE-003")
                            .code("WTC-TWR-03")
                            .name("World Trade Center Hub")
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
                            .build()
            ));
            log.info("Initialized default master sites.");
        }

        // 3. Seed System Settings
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

        // 4. Seed Audit Logs
        if (auditLogRepository.count() == 0) {
            auditLogRepository.save(
                    AuditLogEntity.builder()
                            .id("AUDIT-001")
                            .action("SYSTEM_INITIALIZED")
                            .actorName("System Security Engine")
                            .actorRole("ADMIN")
                            .details("Spring Boot REST Backend with PostgreSQL initialized successfully.")
                            .timestamp(LocalDateTime.now())
                            .targetEntity("SYSTEM")
                            .build()
            );
        }

        log.info("WorkPulse database seeding complete!");
    }
}
