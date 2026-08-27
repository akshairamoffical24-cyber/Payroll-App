package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "excel_import_errors", indexes = {
    @Index(name = "idx_import_err_import_id", columnList = "import_id")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExcelImportErrorEntity {

    @Id
    @Column(length = 64)
    private String id;

    @Column(name = "import_id", nullable = false, length = 64)
    private String importId;

    @Column(name = "row_number", nullable = false)
    private Integer rowNumber;

    @Column(name = "field_name", length = 64)
    private String fieldName;

    @Column(name = "error_message", nullable = false, columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
