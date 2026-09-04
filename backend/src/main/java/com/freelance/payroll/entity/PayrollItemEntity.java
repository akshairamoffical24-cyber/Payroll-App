package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Entity
@Table(name = "payroll_items")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PayrollItemEntity {

    @Id
    private String id;

    @Column(name = "payroll_id", nullable = false)
    private String payrollId;

    @Column(nullable = false)
    private String itemName;

    @Column(nullable = false)
    private String itemType; // EARNING, DEDUCTION

    @Column(nullable = false)
    private BigDecimal amount;
}
