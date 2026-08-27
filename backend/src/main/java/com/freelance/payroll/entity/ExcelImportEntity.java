package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "excel_imports", indexes = {
    @Index(name = "idx_import_status", columnList = "status"),
    @Index(name = "idx_import_uploaded_at", columnList = "uploaded_at")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExcelImportEntity {

    @Id
    @Column(length = 64)
    private String id;

    @Column(name = "file_name", nullable = false)
    private String fileName;

    @Column(name = "uploaded_by", length = 64)
    private String uploadedBy;

    @Column(name = "uploaded_at", nullable = false)
    private LocalDateTime uploadedAt;

    @Column(name = "total_rows")
    private Integer totalRows;

    @Column(name = "successful_rows")
    private Integer successfulRows;

    @Column(name = "updated_rows")
    private Integer updatedRows;

    @Column(name = "failed_rows")
    private Integer failedRows;

    @Column(name = "status", length = 32, nullable = false)
    private String status; // PROCESSING, COMPLETED, COMPLETED_WITH_ERRORS, FAILED

    @Column(name = "error_summary", columnDefinition = "TEXT")
    private String errorSummary;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
