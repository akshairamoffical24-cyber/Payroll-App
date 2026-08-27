package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "employee_site_mappings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeSiteMappingEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String employeeId;

    @Column(nullable = false)
    private String siteId;

    @Column(nullable = false)
    private LocalDate fromDate;

    private LocalDate toDate;

    @Column(nullable = false)
    private String status; // active, inactive

    private String createdBy;
    private LocalDateTime createdDate;
    private LocalDateTime updatedDate;
}
