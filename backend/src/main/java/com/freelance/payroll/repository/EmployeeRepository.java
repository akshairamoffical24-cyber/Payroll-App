package com.freelance.payroll.repository;

import com.freelance.payroll.entity.EmployeeEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeRepository extends JpaRepository<EmployeeEntity, String> {
    Optional<EmployeeEntity> findByCode(String code);
    Optional<EmployeeEntity> findByCodeIgnoreCase(String code);
    Optional<EmployeeEntity> findByEmailIgnoreCase(String email);
    List<EmployeeEntity> findByDepartmentIgnoreCase(String department);
    List<EmployeeEntity> findByStatusIgnoreCase(String status);
    List<EmployeeEntity> findByTypeIgnoreCase(String type);
}
