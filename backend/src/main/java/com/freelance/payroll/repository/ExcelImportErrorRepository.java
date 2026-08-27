package com.freelance.payroll.repository;

import com.freelance.payroll.entity.ExcelImportErrorEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ExcelImportErrorRepository extends JpaRepository<ExcelImportErrorEntity, String> {
    List<ExcelImportErrorEntity> findByImportIdOrderByRowNumberAsc(String importId);
}
