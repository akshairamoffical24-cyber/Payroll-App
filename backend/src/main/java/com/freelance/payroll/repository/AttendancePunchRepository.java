package com.freelance.payroll.repository;

import com.freelance.payroll.entity.AttendancePunchEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AttendancePunchRepository extends JpaRepository<AttendancePunchEntity, String> {
    List<AttendancePunchEntity> findByEmployeeIdOrderByTimestampAsc(String employeeId);
    List<AttendancePunchEntity> findByEmployeeIdAndTimestampBetween(String employeeId, LocalDateTime start, LocalDateTime end);
    List<AttendancePunchEntity> findByEmployeeIdAndTimestampBetweenOrderByTimestampAsc(
            String employeeId, LocalDateTime start, LocalDateTime end);
    List<AttendancePunchEntity> findByIsPendingSyncTrue();
    List<AttendancePunchEntity> findTop100ByOrderByTimestampDesc();
}
