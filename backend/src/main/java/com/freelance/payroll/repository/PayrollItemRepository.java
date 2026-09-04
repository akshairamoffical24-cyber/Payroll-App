package com.freelance.payroll.repository;

import com.freelance.payroll.entity.PayrollItemEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PayrollItemRepository extends JpaRepository<PayrollItemEntity, String> {
    List<PayrollItemEntity> findByPayrollId(String payrollId);
    void deleteByPayrollId(String payrollId);
}
