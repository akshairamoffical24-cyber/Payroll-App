package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.NotificationEntity;
import com.freelance.payroll.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    @Autowired
    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationEntity>>> getAllNotifications() {
        return ResponseEntity.ok(ApiResponse.success(notificationService.getAllNotifications()));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<NotificationEntity>> addNotification(@RequestBody NotificationEntity notif) {
        NotificationEntity created = notificationService.addNotification(notif);
        return ResponseEntity.ok(ApiResponse.success("Notification added", created));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable("id") String id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok(ApiResponse.success("Notification marked as read", null));
    }

    @PatchMapping("/mark-all-read")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead() {
        notificationService.markAllAsRead();
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> clearAllNotifications() {
        notificationService.clearAll();
        return ResponseEntity.ok(ApiResponse.success("All notifications cleared successfully", null));
    }
}
