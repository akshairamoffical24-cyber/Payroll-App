package com.freelance.payroll.repository;

import com.freelance.payroll.entity.ExcelImportEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ExcelImportRepository extends JpaRepository<ExcelImportEntity, String> {
    List<ExcelImportEntity> findAllByOrderByUploadedAtDesc();
}
