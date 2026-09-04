package com.freelance.payroll.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SiteRequest {
    private String code;
    private String name;
    private String client;
    private String project;
    private String address;
    private Double latitude;
    private Double longitude;
    private Double geofenceRadius;
    private String status;
}
