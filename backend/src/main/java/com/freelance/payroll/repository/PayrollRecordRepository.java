package com.freelance.payroll.repository;

import com.freelance.payroll.entity.PayrollRecordEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface PayrollRecordRepository extends JpaRepository<PayrollRecordEntity, String> {
    List<PayrollRecordEntity> findByMonthOrderByEmployeeIdAsc(LocalDate month);
    List<PayrollRecordEntity> findByEmployeeIdOrderByMonthDesc(String employeeId);
    Optional<PayrollRecordEntity> findByEmployeeIdAndMonth(String employeeId, LocalDate month);
}
