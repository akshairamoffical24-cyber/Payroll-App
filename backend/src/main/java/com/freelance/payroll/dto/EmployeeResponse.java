package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeResponse {
    private String id;
    private String code;
    private String name;
    private String department;
    private String designation;
    private String type;
    private String phone;
    private String email;
    private String status;
    private LocalDate joiningDate;
    private Double monthlyCtc;
    private Double basicSalary;
    private String avatarUrl;
}
