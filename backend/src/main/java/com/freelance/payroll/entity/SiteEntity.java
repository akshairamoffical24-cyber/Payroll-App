package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "sites")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SiteEntity {

    @Id
    private String id;

    @Column(nullable = false, unique = true)
    private String code; // e.g. SITE001

    @Column(nullable = false)
    private String name;

    private String client;
    private String project;
    private String address;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private Double geofenceRadius; // meters

    private String poNumber;
    private String siteManagerName;
    private String siteEngineerName;

    @Column(nullable = false)
    private String status; // active, inactive
}
