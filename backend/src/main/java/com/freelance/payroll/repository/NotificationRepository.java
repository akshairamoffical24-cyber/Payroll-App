package com.freelance.payroll.repository;

import com.freelance.payroll.entity.NotificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<NotificationEntity, String> {
    List<NotificationEntity> findAllByOrderByTimestampDesc();
    List<NotificationEntity> findByIsReadFalseOrderByTimestampDesc();
}
