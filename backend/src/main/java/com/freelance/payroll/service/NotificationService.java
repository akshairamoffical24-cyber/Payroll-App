package com.freelance.payroll.service;

import com.freelance.payroll.entity.NotificationEntity;
import com.freelance.payroll.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    @Autowired
    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public List<NotificationEntity> getAllNotifications() {
        return notificationRepository.findAllByOrderByTimestampDesc();
    }

    public NotificationEntity addNotification(NotificationEntity notif) {
        if (notif.getId() == null || notif.getId().isEmpty()) {
            notif.setId("NOTIF-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }
        if (notif.getTimestamp() == null) {
            notif.setTimestamp(LocalDateTime.now());
        }
        if (notif.getIsRead() == null) {
            notif.setIsRead(false);
        }
        return notificationRepository.save(notif);
    }

    public void markAsRead(String id) {
        notificationRepository.findById(id).ifPresent(n -> {
            n.setIsRead(true);
            notificationRepository.save(n);
        });
    }

    public void markAllAsRead() {
        List<NotificationEntity> list = notificationRepository.findAll();
        list.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(list);
    }

    public void clearAll() {
        notificationRepository.deleteAll();
    }
}
