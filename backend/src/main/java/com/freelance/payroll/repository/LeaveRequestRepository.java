package com.freelance.payroll.repository;

import com.freelance.payroll.entity.LeaveRequestEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequestEntity, String> {
    List<LeaveRequestEntity> findByEmployeeIdOrderByCreatedAtDesc(String employeeId);
    List<LeaveRequestEntity> findByStatusIgnoreCaseOrderByCreatedAtDesc(String status);
    List<LeaveRequestEntity> findByStartDateBetweenOrEndDateBetween(LocalDate start1, LocalDate end1, LocalDate start2, LocalDate end2);
    long countByStatusIgnoreCase(String status);
}
