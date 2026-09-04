package com.freelance.payroll.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "sites", indexes = {
    @Index(name = "idx_site_code", columnList = "code", unique = true),
    @Index(name = "idx_site_status", columnList = "status")
})
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
    private String clientName;
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

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (status == null) status = "active";
        if (geofenceRadius == null) geofenceRadius = 150.0;
        if (clientName == null && client != null) clientName = client;
        if (client == null && clientName != null) client = clientName;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        if (clientName == null && client != null) clientName = client;
        if (client == null && clientName != null) client = clientName;
    }
}
