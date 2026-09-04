package com.freelance.payroll.service;

import com.freelance.payroll.dto.AttendanceRequest;
import com.freelance.payroll.dto.MobilePunchRequest;
import com.freelance.payroll.entity.*;
import com.freelance.payroll.exception.BadRequestException;
import com.freelance.payroll.exception.ResourceNotFoundException;
import com.freelance.payroll.repository.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Slf4j
@Service
public class AttendanceService {

    private final AttendancePunchRepository punchRepository;
    private final DailyAttendanceRepository dailyRepository;
    private final SiteRepository siteRepository;
    private final EmployeeRepository employeeRepository;
    private final HaversineService haversineService;
    private final MappingService mappingService;
    private final AuditLogRepository auditLogRepository;

    @Autowired
    public AttendanceService(
            AttendancePunchRepository punchRepository,
            DailyAttendanceRepository dailyRepository,
            SiteRepository siteRepository,
            EmployeeRepository employeeRepository,
            HaversineService haversineService,
            MappingService mappingService,
            AuditLogRepository auditLogRepository) {
        this.punchRepository = punchRepository;
        this.dailyRepository = dailyRepository;
        this.siteRepository = siteRepository;
        this.employeeRepository = employeeRepository;
        this.haversineService = haversineService;
        this.mappingService = mappingService;
        this.auditLogRepository = auditLogRepository;
    }

    public List<AttendancePunchEntity> getAllPunches() {
        return punchRepository.findTop100ByOrderByTimestampDesc();
    }

    public List<DailyAttendanceEntity> getDailyAttendanceList(LocalDate date, String employeeId) {
        if (date != null && employeeId != null) {
            return dailyRepository.findByEmployeeIdAndDate(employeeId, date)
                    .map(Collections::singletonList)
                    .orElse(Collections.emptyList());
        } else if (date != null) {
            return dailyRepository.findByDateOrderByEmployeeIdAsc(date);
        } else if (employeeId != null) {
            return dailyRepository.findByEmployeeIdOrderByDateDesc(employeeId);
        } else {
            return dailyRepository.findAll();
        }
    }

    public List<DailyAttendanceEntity> getTodayAttendance() {
        return dailyRepository.findByDateOrderByEmployeeIdAsc(LocalDate.now());
    }

    public List<DailyAttendanceEntity> getAttendanceRange(LocalDate from, LocalDate to) {
        LocalDate start = from != null ? from : LocalDate.now().minusDays(30);
        LocalDate end = to != null ? to : LocalDate.now();
        return dailyRepository.findByDateBetween(start, end);
    }

    public Optional<DailyAttendanceEntity> getDailyAttendanceForEmployee(String employeeId, LocalDate date) {
        return dailyRepository.findByEmployeeIdAndDate(employeeId, date);
    }

    public Optional<DailyAttendanceEntity> getAttendanceById(String id) {
        return dailyRepository.findById(id);
    }

    public List<DailyAttendanceEntity> getAttendanceByEmployee(String employeeId) {
        return dailyRepository.findByEmployeeIdOrderByDateDesc(employeeId);
    }

    public List<DailyAttendanceEntity> getAttendanceByDate(LocalDate date) {
        return dailyRepository.findByDateOrderByEmployeeIdAsc(date);
    }

    @Transactional
    public DailyAttendanceEntity checkIn(AttendanceRequest request) {
        String empId = request.getEmployeeId();
        if (empId == null || empId.isBlank()) {
            throw new BadRequestException("Employee ID is required for check-in");
        }

        EmployeeEntity employee = employeeRepository.findById(empId)
                .or(() -> employeeRepository.findByCodeIgnoreCase(empId))
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found: " + empId));

        if (!"active".equalsIgnoreCase(employee.getStatus())) {
            throw new BadRequestException("Employee is inactive and cannot check in");
        }

        LocalDateTime now = request.getTimestamp() != null ? request.getTimestamp() : LocalDateTime.now();
        LocalDate today = now.toLocalDate();

        // 1. Verify Site and Geofence
        SiteEntity site = null;
        if (request.getSiteId() != null && !request.getSiteId().isBlank()) {
            site = siteRepository.findById(request.getSiteId())
                    .or(() -> siteRepository.findByCodeIgnoreCase(request.getSiteId()))
                    .orElse(null);
        }

        if (site == null) {
            // Check if employee has an active mapped site for today
            List<String> activeSites = mappingService.getActiveSiteIdsForEmployee(employee.getId(), today);
            if (!activeSites.isEmpty()) {
                site = siteRepository.findById(activeSites.get(0)).orElse(null);
            }
        }

        if (site != null && request.getLatitude() != null && request.getLongitude() != null) {
            double distance = haversineService.calculateDistanceMeters(
                    request.getLatitude(), request.getLongitude(),
                    site.getLatitude(), site.getLongitude()
            );
            if (distance > site.getGeofenceRadius()) {
                throw new BadRequestException("Employee is outside the permitted site geofence.");
            }
        }

        // 2. Prevent duplicate open check-in
        Optional<DailyAttendanceEntity> existingDaily = dailyRepository.findByEmployeeIdAndDate(employee.getId(), today);
        if (existingDaily.isPresent() && existingDaily.get().getFirstPunchTime() != null && existingDaily.get().getLastPunchTime() == null) {
            // Already checked in today without checking out
            return existingDaily.get();
        }

        // 3. Record Punch
        AttendancePunchEntity punch = AttendancePunchEntity.builder()
                .id("PUNCH-" + now.getYear() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .employeeId(employee.getId())
                .timestamp(now)
                .type("inPunch")
                .source("mobile")
                .siteId(site != null ? site.getId() : request.getSiteId())
                .siteName(site != null ? site.getName() : "Office/Field")
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .isVerified(true)
                .build();
        punchRepository.save(punch);

        // 4. Update / Create Daily Attendance
        DailyAttendanceEntity daily;
        if (existingDaily.isPresent()) {
            daily = existingDaily.get();
            daily.setFirstPunchId(punch.getId());
            daily.setFirstPunchTime(now);
            daily.setFirstPunchType("inPunch");
            daily.setFirstPunchSource("mobile");
            daily.setFirstPunchSiteName(punch.getSiteName());
        } else {
            daily = DailyAttendanceEntity.builder()
                    .id("ATT-" + today.getYear() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .employeeId(employee.getId())
                    .date(today)
                    .firstPunchId(punch.getId())
                    .firstPunchTime(now)
                    .firstPunchType("inPunch")
                    .firstPunchSource("mobile")
                    .firstPunchSiteName(punch.getSiteName())
                    .status(now.getHour() >= 10 ? "late" : "present")
                    .sourceType("mobile")
                    .remarks(request.getRemarks())
                    .payrollWorkingDaysCredit(1.0)
                    .build();
        }

        DailyAttendanceEntity saved = dailyRepository.save(daily);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("CHECK_IN")
                    .actorName(employee.getName())
                    .actorRole("STAFF")
                    .targetEntity("ATTENDANCE")
                    .details("Checked in at " + now.toLocalTime() + " at " + punch.getSiteName())
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public DailyAttendanceEntity checkOut(AttendanceRequest request) {
        String empId = request.getEmployeeId();
        if (empId == null || empId.isBlank()) {
            throw new BadRequestException("Employee ID is required for check-out");
        }

        EmployeeEntity employee = employeeRepository.findById(empId)
                .or(() -> employeeRepository.findByCodeIgnoreCase(empId))
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found: " + empId));

        LocalDateTime now = request.getTimestamp() != null ? request.getTimestamp() : LocalDateTime.now();
        LocalDate today = now.toLocalDate();

        DailyAttendanceEntity daily = dailyRepository.findByEmployeeIdAndDate(employee.getId(), today)
                .or(() -> dailyRepository.findByEmployeeIdAndDate(employee.getId(), today.minusDays(1))
                        .filter(d -> d.getFirstPunchTime() != null && d.getLastPunchTime() == null))
                .orElseThrow(() -> new BadRequestException("No active check-in record found for today. Please check in first."));

        if (daily.getFirstPunchTime() == null) {
            throw new BadRequestException("No check-in timestamp found for today.");
        }

        SiteEntity site = null;
        if (request.getSiteId() != null) {
            site = siteRepository.findById(request.getSiteId()).orElse(null);
        }

        // Record out-punch
        AttendancePunchEntity punch = AttendancePunchEntity.builder()
                .id("PUNCH-" + now.getYear() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .employeeId(employee.getId())
                .timestamp(now)
                .type("outPunch")
                .source("mobile")
                .siteId(site != null ? site.getId() : request.getSiteId())
                .siteName(site != null ? site.getName() : "Office/Field")
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .isVerified(true)
                .build();
        punchRepository.save(punch);

        // Calculate working hours & minutes
        long workingMinutes = Math.max(0, Duration.between(daily.getFirstPunchTime(), now).toMinutes());
        daily.setLastPunchId(punch.getId());
        daily.setLastPunchTime(now);
        daily.setLastPunchType("outPunch");
        daily.setLastPunchSource("mobile");
        daily.setLastPunchSiteName(punch.getSiteName());
        daily.setWorkingMinutes(workingMinutes);

        if (workingMinutes >= 480) { // >= 8 hours
            daily.setStatus("present");
            daily.setPayrollWorkingDaysCredit(1.0);
        } else if (workingMinutes >= 240) { // >= 4 hours
            daily.setStatus("halfDay");
            daily.setPayrollWorkingDaysCredit(0.5);
        }

        DailyAttendanceEntity saved = dailyRepository.save(daily);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("CHECK_OUT")
                    .actorName(employee.getName())
                    .actorRole("STAFF")
                    .targetEntity("ATTENDANCE")
                    .details("Checked out at " + now.toLocalTime() + " (Worked " + (workingMinutes / 60) + "h " + (workingMinutes % 60) + "m)")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public AttendancePunchEntity recordMobilePunch(MobilePunchRequest request) {
        LocalDateTime now = request.getTimestamp() != null ? request.getTimestamp() : LocalDateTime.now();

        // 1. Rapid duplicate punch prevention (30s window)
        List<AttendancePunchEntity> existingPunches = punchRepository.findByEmployeeIdOrderByTimestampAsc(request.getEmployeeId());
        Optional<AttendancePunchEntity> duplicateOpt = existingPunches.stream()
                .filter(p -> p.getType().equalsIgnoreCase(request.getType()) &&
                        (p.getSiteId() == null || p.getSiteId().equals(request.getSiteId())) &&
                        Math.abs(Duration.between(p.getTimestamp(), now).getSeconds()) < 30)
                .findFirst();

        if (duplicateOpt.isPresent()) {
            return duplicateOpt.get();
        }

        // 2. Fetch site information
        SiteEntity site = null;
        if (request.getSiteId() != null) {
            site = siteRepository.findById(request.getSiteId()).orElse(null);
        }

        double distance = request.getDistanceMeters() != null ? request.getDistanceMeters() : 0.0;
        if (site != null && request.getLatitude() != null && request.getLongitude() != null) {
            distance = haversineService.calculateDistanceMeters(
                    request.getLatitude(), request.getLongitude(),
                    site.getLatitude(), site.getLongitude()
            );
        }

        boolean isVerified = true;
        if (site != null) {
            boolean inGeofence = distance <= site.getGeofenceRadius();
            List<String> activeSites = mappingService.getActiveSiteIdsForEmployee(request.getEmployeeId(), now.toLocalDate());
            boolean isMapped = activeSites.isEmpty() || activeSites.contains(site.getId());
            isVerified = inGeofence && isMapped;
        }

        AttendancePunchEntity punch = AttendancePunchEntity.builder()
                .id("PUNCH-" + now.getYear() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                .employeeId(request.getEmployeeId())
                .timestamp(now)
                .type(request.getType())
                .source("mobile")
                .siteId(request.getSiteId())
                .siteName(site != null ? site.getName() : request.getSiteName())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy())
                .distanceMeters(distance)
                .isVerified(isVerified)
                .isPendingSync(false)
                .build();

        AttendancePunchEntity savedPunch = punchRepository.save(punch);

        // Aggregate into DailyAttendance
        aggregateDailyAttendanceForEmployee(request.getEmployeeId(), now.toLocalDate());

        return savedPunch;
    }

    private void aggregateDailyAttendanceForEmployee(String employeeId, LocalDate date) {
        List<AttendancePunchEntity> dayPunches = punchRepository.findByEmployeeIdAndTimestampBetween(
                employeeId, date.atStartOfDay(), date.plusDays(1).atStartOfDay()
        );

        if (dayPunches.isEmpty()) return;

        dayPunches.sort(Comparator.comparing(p -> p.getTimestamp()));
        AttendancePunchEntity first = dayPunches.get(0);
        AttendancePunchEntity last = dayPunches.size() > 1 ? dayPunches.get(dayPunches.size() - 1) : null;

        DailyAttendanceEntity daily = dailyRepository.findByEmployeeIdAndDate(employeeId, date)
                .orElse(DailyAttendanceEntity.builder()
                        .id("ATT-" + date.getYear() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                        .employeeId(employeeId)
                        .date(date)
                        .build());

        daily.setFirstPunchId(first.getId());
        daily.setFirstPunchTime(first.getTimestamp());
        daily.setFirstPunchType(first.getType());
        daily.setFirstPunchSource(first.getSource());
        daily.setFirstPunchSiteName(first.getSiteName());

        if (last != null && !last.getId().equals(first.getId())) {
            daily.setLastPunchId(last.getId());
            daily.setLastPunchTime(last.getTimestamp());
            daily.setLastPunchType(last.getType());
            daily.setLastPunchSource(last.getSource());
            daily.setLastPunchSiteName(last.getSiteName());

            long workingMinutes = Math.max(0, Duration.between(first.getTimestamp(), last.getTimestamp()).toMinutes());
            daily.setWorkingMinutes(workingMinutes);

            if (workingMinutes >= 480) {
                daily.setStatus("present");
                daily.setPayrollWorkingDaysCredit(1.0);
            } else if (workingMinutes >= 240) {
                daily.setStatus("halfDay");
                daily.setPayrollWorkingDaysCredit(0.5);
            } else {
                daily.setStatus("absent");
                daily.setPayrollWorkingDaysCredit(0.0);
            }
        } else {
            daily.setStatus(first.getTimestamp().getHour() >= 10 ? "late" : "present");
            daily.setPayrollWorkingDaysCredit(1.0);
        }

        dailyRepository.save(daily);
    }

    public void recalculateDailyAttendance(String employeeId, LocalDate date) {
        aggregateDailyAttendanceForEmployee(employeeId, date);
    }
}
