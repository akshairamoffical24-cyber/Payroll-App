package com.freelance.payroll.repository;

import com.freelance.payroll.entity.RegularizationRequestEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RegularizationRequestRepository extends JpaRepository<RegularizationRequestEntity, String> {
    List<RegularizationRequestEntity> findByEmployeeIdOrderByAppliedAtDesc(String employeeId);
    List<RegularizationRequestEntity> findByStatusOrderByAppliedAtDesc(String status);
    List<RegularizationRequestEntity> findAllByOrderByAppliedAtDesc();
}
