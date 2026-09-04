package com.freelance.payroll.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "employees", indexes = {
    @Index(name = "idx_emp_code", columnList = "code", unique = true),
    @Index(name = "idx_emp_email", columnList = "email"),
    @Index(name = "idx_emp_department", columnList = "department"),
    @Index(name = "idx_emp_status", columnList = "status")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class EmployeeEntity {

    @Id
    private String id;

    @Column(nullable = false, unique = true)
    private String code; // e.g. EMP001, E048

    @Column(nullable = false)
    private String name;

    private String department;
    private String designation;
    private String type; // office, field, full-time, part-time
    private String phone;
    private String email;
    private String status; // active, inactive

    @JsonFormat(pattern = "yyyy-MM-dd[ 'T'HH:mm:ss[.SSS][XXX]]")
    private LocalDate joiningDate;

    private String workLocation;
    private String gender;
    private Boolean portalAccess;
    private Boolean epfEnabled;
    private Boolean esiEnabled;
    private Boolean epsContribution;
    private Boolean professionalTaxEnabled;
    private String pfAccountNumber;
    private String uan;

    @JsonFormat(pattern = "yyyy-MM-dd[ 'T'HH:mm:ss[.SSS][XXX]]")
    private LocalDate dob;

    private String fatherName;
    private String address;
    private String pan;
    private String differentlyAbledType;
    private String paymentMode;
    private String bankName;
    private String accountNumber;
    private String ifsc;
    private String accountType;
    private Double monthlyCtc;
    private Double annualCtc;
    private Double basicSalary;
    private Double hra;
    private Double specialAllowance;
    private String incrementCycle;
    private Double incrementPercentage;
    @JsonFormat(pattern = "yyyy-MM-dd[ 'T'HH:mm:ss[.SSS][XXX]]")
    private LocalDate nextIncrementDate;
    private Integer probationPeriodMonths;
    private Double epfEmployerMonthly;
    private Double epfEmployerAnnual;
    private String avatarUrl;
    private String biometricId;

    private Boolean isFaceRegistered;
    @JsonFormat(pattern = "yyyy-MM-dd[ 'T'HH:mm:ss[.SSS][XXX]]")
    private LocalDateTime faceRegisteredAt;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (status == null) status = "active";
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Double getSalary() {
        if (monthlyCtc != null) return monthlyCtc;
        if (basicSalary != null) return basicSalary;
        return 0.0;
    }

    public void setSalary(Double salary) {
        this.monthlyCtc = salary;
        this.basicSalary = salary != null ? salary * 0.5 : 0.0;
    }
}
