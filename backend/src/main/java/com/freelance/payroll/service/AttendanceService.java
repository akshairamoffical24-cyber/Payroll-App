package com.freelance.payroll.service;

import com.freelance.payroll.dto.MobilePunchRequest;
import com.freelance.payroll.entity.AttendancePunchEntity;
import com.freelance.payroll.entity.DailyAttendanceEntity;
import com.freelance.payroll.entity.SiteEntity;
import com.freelance.payroll.repository.AttendancePunchRepository;
import com.freelance.payroll.repository.DailyAttendanceRepository;
import com.freelance.payroll.repository.SiteRepository;
import org.springframework.stereotype.Service;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AttendanceService {

    private final AttendancePunchRepository punchRepository;
    private final DailyAttendanceRepository dailyRepository;
    private final SiteRepository siteRepository;
    private final HaversineService haversineService;
    private final MappingService mappingService;

    @org.springframework.beans.factory.annotation.Autowired
    public AttendanceService(
            AttendancePunchRepository punchRepository,
            DailyAttendanceRepository dailyRepository,
            SiteRepository siteRepository,
            HaversineService haversineService,
            MappingService mappingService) {
        this.punchRepository = punchRepository;
        this.dailyRepository = dailyRepository;
        this.siteRepository = siteRepository;
        this.haversineService = haversineService;
        this.mappingService = mappingService;
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

    public Optional<DailyAttendanceEntity> getDailyAttendanceForEmployee(String employeeId, LocalDate date) {
        return dailyRepository.findByEmployeeIdAndDate(employeeId, date);
    }

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
                .type(request.getType() != null ? request.getType() : "inPunch")
                .source("mobile")
                .siteId(site != null ? site.getId() : request.getSiteId())
                .siteName(site != null ? site.getName() : "Mobile Site")
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy() != null ? request.getAccuracy() : 5.0)
                .distanceMeters(distance)
                .isVerified(isVerified)
                .isPendingSync(request.getIsOfflineQueued() != null ? request.getIsOfflineQueued() : false)
                .build();

        punch = punchRepository.save(punch);

        // 3. Recalculate daily roll-up record
        recalculateDailyAttendance(request.getEmployeeId(), now.toLocalDate());

        return punch;
    }

    public int syncOfflinePunches(List<MobilePunchRequest> punches) {
        int synced = 0;
        if (punches != null) {
            for (MobilePunchRequest req : punches) {
                req.setIsOfflineQueued(false);
                recordMobilePunch(req);
                synced++;
            }
        }
        return synced;
    }

    public void recalculateDailyAttendance(String employeeId, LocalDate targetDate) {
        LocalDateTime startOfDay = targetDate.atStartOfDay();
        LocalDateTime endOfDay = targetDate.atTime(23, 59, 59);

        List<AttendancePunchEntity> punchesForDay = punchRepository
                .findByEmployeeIdAndTimestampBetweenOrderByTimestampAsc(employeeId, startOfDay, endOfDay);

        if (punchesForDay.isEmpty()) {
            return;
        }

        AttendancePunchEntity firstPunch = punchesForDay.get(0);
        AttendancePunchEntity lastPunch = punchesForDay.size() > 1 ? punchesForDay.get(punchesForDay.size() - 1) : null;

        Set<String> visitedSites = punchesForDay.stream()
                .map(p -> p.getSiteName() != null ? p.getSiteName() : "Assigned Location")
                .collect(Collectors.toSet());

        long workingMinutes = 0;
        if (lastPunch != null) {
            workingMinutes = Duration.between(firstPunch.getTimestamp(), lastPunch.getTimestamp()).toMinutes();
        }

        // Determine status
        String status = "present";
        int hour = firstPunch.getTimestamp().getHour();
        int min = firstPunch.getTimestamp().getMinute();
        if (hour > 9 || (hour == 9 && min > 30)) {
            status = "late";
        }

        String remarks = null;
        if (visitedSites.size() > 1) {
            remarks = "Visited " + visitedSites.size() + " mapped sites. 1 Working Day credited.";
        }

        DailyAttendanceEntity dailyRecord = dailyRepository.findByEmployeeIdAndDate(employeeId, targetDate)
                .orElse(DailyAttendanceEntity.builder()
                        .id("ATT-" + targetDate.toString() + "-" + employeeId)
                        .employeeId(employeeId)
                        .date(targetDate)
                        .build());

        dailyRecord.setFirstPunchId(firstPunch.getId());
        dailyRecord.setFirstPunchTime(firstPunch.getTimestamp());
        dailyRecord.setFirstPunchType(firstPunch.getType());
        dailyRecord.setFirstPunchSource(firstPunch.getSource());
        dailyRecord.setFirstPunchSiteName(firstPunch.getSiteName());

        if (lastPunch != null) {
            dailyRecord.setLastPunchId(lastPunch.getId());
            dailyRecord.setLastPunchTime(lastPunch.getTimestamp());
            dailyRecord.setLastPunchType(lastPunch.getType());
            dailyRecord.setLastPunchSource(lastPunch.getSource());
            dailyRecord.setLastPunchSiteName(lastPunch.getSiteName());
        }

        dailyRecord.setVisitedSiteNamesJson(String.join(", ", visitedSites));
        dailyRecord.setWorkingMinutes(workingMinutes);
        dailyRecord.setStatus(status);
        dailyRecord.setSourceType("mobile");
        dailyRecord.setRemarks(remarks);
        dailyRecord.setPayrollWorkingDaysCredit(1.0); // 1.0 full working day for multiple sites

        dailyRepository.save(dailyRecord);
    }
}
