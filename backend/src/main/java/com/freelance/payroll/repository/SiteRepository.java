package com.freelance.payroll.repository;

import com.freelance.payroll.entity.SiteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface SiteRepository extends JpaRepository<SiteEntity, String> {
    Optional<SiteEntity> findByCodeIgnoreCase(String code);
    List<SiteEntity> findByStatusIgnoreCase(String status);
}
