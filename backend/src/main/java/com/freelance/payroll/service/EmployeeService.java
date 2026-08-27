package com.freelance.payroll.service;

import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.NotificationEntity;
import com.freelance.payroll.entity.UserEntity;
import com.freelance.payroll.repository.AuditLogRepository;
import com.freelance.payroll.repository.EmployeeRepository;
import com.freelance.payroll.repository.NotificationRepository;
import com.freelance.payroll.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final UserRepository userRepository;
    private final AuditLogRepository auditLogRepository;
    private final NotificationRepository notificationRepository;

    @Autowired
    public EmployeeService(
            EmployeeRepository employeeRepository,
            UserRepository userRepository,
            AuditLogRepository auditLogRepository,
            NotificationRepository notificationRepository) {
        this.employeeRepository = employeeRepository;
        this.userRepository = userRepository;
        this.auditLogRepository = auditLogRepository;
        this.notificationRepository = notificationRepository;
    }

    public List<EmployeeEntity> getAllEmployees() {
        return employeeRepository.findAll();
    }

    public Optional<EmployeeEntity> getEmployeeById(String id) {
        return employeeRepository.findById(id);
    }

    public Optional<EmployeeEntity> getEmployeeByCode(String code) {
        return employeeRepository.findByCodeIgnoreCase(code);
    }

    public EmployeeEntity createEmployee(EmployeeEntity employee) {
        if (employee.getId() == null || employee.getId().isEmpty()) {
            employee.setId("EMP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }
        if (employee.getStatus() == null) {
            employee.setStatus("active");
        }
        
        // 1. Save Employee into EMPLOYEES table
        EmployeeEntity saved = employeeRepository.save(employee);

        // 2. Automatically create login credentials in USERS table
        if (saved.getEmail() != null && !saved.getEmail().isEmpty()) {
            String role = "field".equalsIgnoreCase(saved.getType()) ? "fieldStaff" : "hr";
            Optional<UserEntity> existingUser = userRepository.findByEmailIgnoreCase(saved.getEmail());
            if (existingUser.isEmpty()) {
                UserEntity user = new UserEntity();
                user.setId("USER-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
                user.setEmail(saved.getEmail().toLowerCase().trim());
                user.setPassword("changeme2026!");
                user.setName(saved.getName());
                user.setRole(role);
                user.setEmployeeId(saved.getId());
                user.setDepartment(saved.getDepartment());
                user.setAvatarUrl(saved.getAvatarUrl());
                userRepository.save(user);
            }
        }

        // 3. Save Audit Log into AUDIT_LOGS table
        AuditLogEntity audit = new AuditLogEntity();
        audit.setId("AUDIT-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        audit.setAction("EMPLOYEE_ONBOARDED");
        audit.setActorName("HR Administrator");
        audit.setActorRole("HR");
        audit.setDetails("Onboarded employee " + saved.getName() + " (" + saved.getCode() + ") in " + saved.getDepartment());
        audit.setTimestamp(LocalDateTime.now());
        audit.setTargetEntity(saved.getId());
        auditLogRepository.save(audit);

        // 4. Save Notification into NOTIFICATIONS table
        NotificationEntity notif = new NotificationEntity();
        notif.setId("NOTIF-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        notif.setTitle("New Employee Onboarded");
        notif.setMessage(saved.getName() + " has been onboarded into " + saved.getDepartment() + " department.");
        notif.setType("info");
        notif.setCategory("general");
        notif.setActionRoute("/employees");
        notif.setTimestamp(LocalDateTime.now());
        notif.setIsRead(false);
        notificationRepository.save(notif);

        return saved;
    }

    public EmployeeEntity updateEmployee(String id, EmployeeEntity updated) {
        updated.setId(id);
        return employeeRepository.save(updated);
    }

    public void toggleStatus(String id) {
        employeeRepository.findById(id).ifPresent(emp -> {
            emp.setStatus("active".equalsIgnoreCase(emp.getStatus()) ? "inactive" : "active");
            employeeRepository.save(emp);
        });
    }

    public void deleteEmployee(String id) {
        employeeRepository.deleteById(id);
    }

    public void deleteAllEmployees() {
        employeeRepository.deleteAll();
    }

    public List<EmployeeEntity> importEmployees(String mode, List<EmployeeEntity> employees) {
        List<EmployeeEntity> savedList = new java.util.ArrayList<>();
        if (employees == null) return savedList;

        for (EmployeeEntity emp : employees) {
            if (emp.getId() == null || emp.getId().trim().isEmpty()) {
                emp.setId("EMP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
            }
            if (emp.getCode() == null || emp.getCode().trim().isEmpty()) {
                emp.setCode("EMP" + UUID.randomUUID().toString().substring(0, 5).toUpperCase());
            }
            if (emp.getStatus() == null || emp.getStatus().trim().isEmpty()) {
                emp.setStatus("active");
            }
            if (emp.getType() == null || emp.getType().trim().isEmpty()) {
                emp.setType("field");
            }

            Optional<EmployeeEntity> existingOpt = employeeRepository.findByCodeIgnoreCase(emp.getCode());
            if (existingOpt.isPresent()) {
                if ("addOnly".equalsIgnoreCase(mode)) {
                    continue; // Skip existing in add-only mode
                }
                EmployeeEntity existing = existingOpt.get();
                emp.setId(existing.getId());
                EmployeeEntity updated = employeeRepository.save(emp);
                savedList.add(updated);
            } else {
                if ("updateOnly".equalsIgnoreCase(mode)) {
                    continue; // Skip new records in update-only mode
                }
                EmployeeEntity saved = createEmployee(emp);
                savedList.add(saved);
            }
        }
        return savedList;
    }
}
