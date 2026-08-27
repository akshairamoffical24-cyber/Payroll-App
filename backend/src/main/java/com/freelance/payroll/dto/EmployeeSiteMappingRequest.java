package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeSiteMappingRequest {
    private String employeeId;
    private List<String> siteIds;
    private LocalDate fromDate;
    private LocalDate toDate;
    private String actorName;
}
