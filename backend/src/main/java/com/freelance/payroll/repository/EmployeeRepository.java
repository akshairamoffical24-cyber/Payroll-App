package com.freelance.payroll.repository;

import com.freelance.payroll.entity.EmployeeEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeRepository extends JpaRepository<EmployeeEntity, String> {
    Optional<EmployeeEntity> findByCode(String code);
    Optional<EmployeeEntity> findByCodeIgnoreCase(String code);
    Optional<EmployeeEntity> findByEmailIgnoreCase(String email);
    Optional<EmployeeEntity> findByPhone(String phone);
    List<EmployeeEntity> findByDepartmentIgnoreCase(String department);
    Page<EmployeeEntity> findByDepartmentIgnoreCase(String department, Pageable pageable);
    List<EmployeeEntity> findByStatusIgnoreCase(String status);
    List<EmployeeEntity> findByTypeIgnoreCase(String type);
    long countByStatusIgnoreCase(String status);

    @Query("SELECT e FROM EmployeeEntity e WHERE LOWER(e.name) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(e.code) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(e.email) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<EmployeeEntity> searchEmployees(@Param("query") String query);

    @Query("SELECT e FROM EmployeeEntity e WHERE LOWER(e.name) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(e.code) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(e.email) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<EmployeeEntity> searchEmployees(@Param("query") String query, Pageable pageable);
}
