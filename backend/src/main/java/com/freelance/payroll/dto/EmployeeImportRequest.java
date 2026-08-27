package com.freelance.payroll.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.freelance.payroll.entity.EmployeeEntity;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class EmployeeImportRequest {
    private String mode;
    private List<EmployeeEntity> employees;
}
