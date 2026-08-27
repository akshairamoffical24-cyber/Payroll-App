package com.freelance.payroll.repository;

import com.freelance.payroll.entity.DailyAttendanceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailyAttendanceRepository extends JpaRepository<DailyAttendanceEntity, String> {
    List<DailyAttendanceEntity> findByDateOrderByEmployeeIdAsc(LocalDate date);
    List<DailyAttendanceEntity> findByEmployeeIdOrderByDateDesc(String employeeId);
    Optional<DailyAttendanceEntity> findByEmployeeIdAndDate(String employeeId, LocalDate date);
    List<DailyAttendanceEntity> findByDateBetween(LocalDate start, LocalDate end);
    List<DailyAttendanceEntity> findByEmployeeIdAndDateBetween(String employeeId, LocalDate start, LocalDate end);
}
