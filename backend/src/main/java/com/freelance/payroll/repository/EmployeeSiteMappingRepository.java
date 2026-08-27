package com.freelance.payroll.repository;

import com.freelance.payroll.entity.EmployeeSiteMappingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeSiteMappingRepository extends JpaRepository<EmployeeSiteMappingEntity, String> {
    List<EmployeeSiteMappingEntity> findByEmployeeId(String employeeId);
    List<EmployeeSiteMappingEntity> findBySiteId(String siteId);
    List<EmployeeSiteMappingEntity> findByEmployeeIdAndStatusIgnoreCase(String employeeId, String status);
    Optional<EmployeeSiteMappingEntity> findByEmployeeIdAndSiteId(String employeeId, String siteId);
}
