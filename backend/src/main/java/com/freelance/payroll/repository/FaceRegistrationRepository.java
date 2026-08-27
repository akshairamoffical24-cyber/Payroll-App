package com.freelance.payroll.repository;

import com.freelance.payroll.entity.FaceRegistrationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface FaceRegistrationRepository extends JpaRepository<FaceRegistrationEntity, String> {
    Optional<FaceRegistrationEntity> findByEmployeeIdAndRegistrationStatus(String employeeId, String registrationStatus);
    List<FaceRegistrationEntity> findByEmployeeIdOrderByRegisteredAtDesc(String employeeId);
}
