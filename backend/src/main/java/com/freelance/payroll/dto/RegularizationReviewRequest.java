package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegularizationReviewRequest {
    private String status; // approved, rejected
    private String reviewedBy;
    private String reviewComments;
}
