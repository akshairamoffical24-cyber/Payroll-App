package com.freelance.payroll.service;

import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.NotificationEntity;
import com.freelance.payroll.entity.UserEntity;
import com.freelance.payroll.exception.BadRequestException;
import com.freelance.payroll.exception.ResourceNotFoundException;
import com.freelance.payroll.repository.AuditLogRepository;
import com.freelance.payroll.repository.EmployeeRepository;
import com.freelance.payroll.repository.NotificationRepository;
import com.freelance.payroll.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final UserRepository userRepository;
    private final AuditLogRepository auditLogRepository;
    private final NotificationRepository notificationRepository;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    public EmployeeService(
            EmployeeRepository employeeRepository,
            UserRepository userRepository,
            AuditLogRepository auditLogRepository,
            NotificationRepository notificationRepository,
            PasswordEncoder passwordEncoder) {
        this.employeeRepository = employeeRepository;
        this.userRepository = userRepository;
        this.auditLogRepository = auditLogRepository;
        this.notificationRepository = notificationRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<EmployeeEntity> getAllEmployees() {
        return employeeRepository.findAll();
    }

    public Page<EmployeeEntity> getEmployees(Pageable pageable) {
        return employeeRepository.findAll(pageable);
    }

    public Page<EmployeeEntity> searchEmployees(String query, Pageable pageable) {
        if (query == null || query.isBlank()) {
            return employeeRepository.findAll(pageable);
        }
        return employeeRepository.searchEmployees(query.trim(), pageable);
    }

    public List<EmployeeEntity> searchEmployees(String query) {
        if (query == null || query.isBlank()) {
            return employeeRepository.findAll();
        }
        return employeeRepository.searchEmployees(query.trim());
    }

    public Page<EmployeeEntity> getEmployeesByDepartment(String department, Pageable pageable) {
        return employeeRepository.findByDepartmentIgnoreCase(department, pageable);
    }

    public List<EmployeeEntity> getEmployeesByDepartment(String department) {
        return employeeRepository.findByDepartmentIgnoreCase(department);
    }

    public Optional<EmployeeEntity> getEmployeeById(String id) {
        return employeeRepository.findById(id);
    }

    public Optional<EmployeeEntity> getEmployeeByCode(String code) {
        return employeeRepository.findByCodeIgnoreCase(code);
    }

    @Transactional
    public EmployeeEntity createEmployee(EmployeeEntity employee) {
        if (employee.getCode() == null || employee.getCode().isBlank()) {
            employee.setCode("EMP" + UUID.randomUUID().toString().substring(0, 6).toUpperCase());
        }
        if (employee.getName() == null || employee.getName().isBlank()) {
            throw new BadRequestException("Employee name is required");
        }

        Optional<EmployeeEntity> existing = employeeRepository.findByCodeIgnoreCase(employee.getCode());
        if (existing.isPresent()) {
            throw new BadRequestException("Employee code '" + employee.getCode() + "' already exists.");
        }

        if (employee.getId() == null || employee.getId().isBlank()) {
            employee.setId("EMP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        }
        if (employee.getStatus() == null || employee.getStatus().isBlank()) {
            employee.setStatus("active");
        }

        EmployeeEntity saved = employeeRepository.save(employee);

        // Auto-provision user account if email exists
        if (saved.getEmail() != null && !saved.getEmail().isBlank()) {
            String email = saved.getEmail().toLowerCase().trim();
            Optional<UserEntity> existingUser = userRepository.findByEmailIgnoreCase(email);
            if (existingUser.isEmpty()) {
                String role = "field".equalsIgnoreCase(saved.getType()) ? "FIELD_STAFF" : "HR";
                UserEntity user = UserEntity.builder()
                        .id("USER-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                        .username(saved.getCode())
                        .email(email)
                        .password(passwordEncoder.encode("changeme2026!"))
                        .name(saved.getName())
                        .role(role)
                        .employeeId(saved.getId())
                        .department(saved.getDepartment())
                        .avatarUrl(saved.getAvatarUrl())
                        .active(true)
                        .build();
                userRepository.save(user);
            }
        }

        // Audit Log
        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("CREATE")
                    .actorName("HR/Admin")
                    .actorRole("HR")
                    .targetEntity("EMPLOYEE")
                    .details("Employee " + saved.getName() + " (" + saved.getCode() + ") created in " + saved.getDepartment())
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception e) {
            log.warn("Failed to write audit log: {}", e.getMessage());
        }

        // Notification
        try {
            notificationRepository.save(NotificationEntity.builder()
                    .id("NOTIF-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .title("New Employee Created")
                    .message(saved.getName() + " has been added to the " + saved.getDepartment() + " department.")
                    .type("info")
                    .category("general")
                    .actionRoute("/employees")
                    .timestamp(LocalDateTime.now())
                    .isRead(false)
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public EmployeeEntity updateEmployee(String id, EmployeeEntity updated) {
        EmployeeEntity existing = employeeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + id));

        if (updated.getCode() != null && !updated.getCode().equalsIgnoreCase(existing.getCode())) {
            Optional<EmployeeEntity> codeCheck = employeeRepository.findByCodeIgnoreCase(updated.getCode());
            if (codeCheck.isPresent() && !codeCheck.get().getId().equals(id)) {
                throw new BadRequestException("Employee code '" + updated.getCode() + "' is already in use by another employee.");
            }
            existing.setCode(updated.getCode());
        }

        if (updated.getName() != null) existing.setName(updated.getName());
        if (updated.getDepartment() != null) existing.setDepartment(updated.getDepartment());
        if (updated.getDesignation() != null) existing.setDesignation(updated.getDesignation());
        if (updated.getType() != null) existing.setType(updated.getType());
        if (updated.getPhone() != null) existing.setPhone(updated.getPhone());
        if (updated.getEmail() != null) existing.setEmail(updated.getEmail());
        if (updated.getStatus() != null) existing.setStatus(updated.getStatus());
        if (updated.getJoiningDate() != null) existing.setJoiningDate(updated.getJoiningDate());
        if (updated.getDob() != null) existing.setDob(updated.getDob());
        if (updated.getGender() != null) existing.setGender(updated.getGender());
        if (updated.getWorkLocation() != null) existing.setWorkLocation(updated.getWorkLocation());
        if (updated.getMonthlyCtc() != null) existing.setMonthlyCtc(updated.getMonthlyCtc());
        if (updated.getAnnualCtc() != null) existing.setAnnualCtc(updated.getAnnualCtc());
        if (updated.getBasicSalary() != null) existing.setBasicSalary(updated.getBasicSalary());
        if (updated.getHra() != null) existing.setHra(updated.getHra());
        if (updated.getSpecialAllowance() != null) existing.setSpecialAllowance(updated.getSpecialAllowance());
        if (updated.getAvatarUrl() != null) existing.setAvatarUrl(updated.getAvatarUrl());

        EmployeeEntity saved = employeeRepository.save(existing);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("UPDATE")
                    .actorName("HR/Admin")
                    .actorRole("HR")
                    .targetEntity("EMPLOYEE")
                    .details("Updated employee details for " + saved.getName() + " (" + saved.getCode() + ")")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}

        return saved;
    }

    @Transactional
    public void deleteEmployee(String id) {
        EmployeeEntity emp = employeeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + id));
        employeeRepository.delete(emp);

        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action("DELETE")
                    .actorName("Admin")
                    .actorRole("ADMIN")
                    .targetEntity("EMPLOYEE")
                    .details("Deleted employee " + emp.getName() + " (" + emp.getCode() + ")")
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception ignored) {}
    }

    public byte[] exportEmployeesToExcel() {
        List<EmployeeEntity> employees = employeeRepository.findAll();
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Employees");

            // Header Style
            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);

            String[] headers = {
                    "Employee Code", "Full Name", "Email", "Phone", "Department",
                    "Designation", "Type", "Status", "Joining Date", "Monthly CTC", "Basic Salary"
            };

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (EmployeeEntity emp : employees) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(emp.getCode() != null ? emp.getCode() : "");
                row.createCell(1).setCellValue(emp.getName() != null ? emp.getName() : "");
                row.createCell(2).setCellValue(emp.getEmail() != null ? emp.getEmail() : "");
                row.createCell(3).setCellValue(emp.getPhone() != null ? emp.getPhone() : "");
                row.createCell(4).setCellValue(emp.getDepartment() != null ? emp.getDepartment() : "");
                row.createCell(5).setCellValue(emp.getDesignation() != null ? emp.getDesignation() : "");
                row.createCell(6).setCellValue(emp.getType() != null ? emp.getType() : "");
                row.createCell(7).setCellValue(emp.getStatus() != null ? emp.getStatus() : "");
                row.createCell(8).setCellValue(emp.getJoiningDate() != null ? emp.getJoiningDate().toString() : "");
                row.createCell(9).setCellValue(emp.getMonthlyCtc() != null ? emp.getMonthlyCtc() : 0.0);
                row.createCell(10).setCellValue(emp.getBasicSalary() != null ? emp.getBasicSalary() : 0.0);
            }

            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to export employees to Excel: " + e.getMessage(), e);
        }
    }

    @Transactional
    public Map<String, Object> importEmployeesFromExcel(MultipartFile file) {
        if (file.isEmpty()) {
            throw new BadRequestException("Uploaded file is empty");
        }

        int totalRows = 0;
        int successfulRows = 0;
        int failedRows = 0;
        List<Map<String, Object>> errors = new ArrayList<>();

        try (InputStream is = file.getInputStream(); Workbook workbook = WorkbookFactory.create(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            Iterator<Row> rowIterator = sheet.iterator();

            if (!rowIterator.hasNext()) {
                throw new BadRequestException("Excel sheet is empty");
            }

            // Skip header
            rowIterator.next();

            int rowNum = 1;
            while (rowIterator.hasNext()) {
                rowNum++;
                Row row = rowIterator.next();
                totalRows++;

                try {
                    String code = getCellValueAsString(row.getCell(0));
                    String name = getCellValueAsString(row.getCell(1));
                    String email = getCellValueAsString(row.getCell(2));
                    String phone = getCellValueAsString(row.getCell(3));
                    String department = getCellValueAsString(row.getCell(4));
                    String designation = getCellValueAsString(row.getCell(5));
                    String type = getCellValueAsString(row.getCell(6));
                    String status = getCellValueAsString(row.getCell(7));
                    String joiningDateStr = getCellValueAsString(row.getCell(8));
                    String salaryStr = getCellValueAsString(row.getCell(9));

                    if (name == null || name.isBlank()) {
                        throw new IllegalArgumentException("Employee name is required");
                    }
                    if (code == null || code.isBlank()) {
                        code = "EMP" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
                    }

                    LocalDate joiningDate = null;
                    if (joiningDateStr != null && !joiningDateStr.isBlank()) {
                        try {
                            joiningDate = LocalDate.parse(joiningDateStr, DateTimeFormatter.ISO_LOCAL_DATE);
                        } catch (Exception ignored) {}
                    }

                    Double salary = 0.0;
                    if (salaryStr != null && !salaryStr.isBlank()) {
                        try {
                            salary = Double.parseDouble(salaryStr.replaceAll("[^0-9.]", ""));
                        } catch (Exception ignored) {}
                    }

                    Optional<EmployeeEntity> existingOpt = employeeRepository.findByCodeIgnoreCase(code);
                    EmployeeEntity emp;
                    if (existingOpt.isPresent()) {
                        emp = existingOpt.get();
                        emp.setName(name);
                        if (email != null) emp.setEmail(email);
                        if (phone != null) emp.setPhone(phone);
                        if (department != null) emp.setDepartment(department);
                        if (designation != null) emp.setDesignation(designation);
                        if (type != null) emp.setType(type);
                        if (status != null) emp.setStatus(status);
                        if (joiningDate != null) emp.setJoiningDate(joiningDate);
                        if (salary > 0) emp.setSalary(salary);
                        employeeRepository.save(emp);
                    } else {
                        emp = EmployeeEntity.builder()
                                .id("EMP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                                .code(code)
                                .name(name)
                                .email(email)
                                .phone(phone)
                                .department(department != null && !department.isBlank() ? department : "Engineering")
                                .designation(designation != null && !designation.isBlank() ? designation : "Staff")
                                .type(type != null && !type.isBlank() ? type : "office")
                                .status(status != null && !status.isBlank() ? status : "active")
                                .joiningDate(joiningDate != null ? joiningDate : LocalDate.now())
                                .monthlyCtc(salary > 0 ? salary : 30000.0)
                                .basicSalary(salary > 0 ? salary * 0.5 : 15000.0)
                                .build();
                        createEmployee(emp);
                    }
                    successfulRows++;
                } catch (Exception e) {
                    failedRows++;
                    Map<String, Object> errorDetails = new HashMap<>();
                    errorDetails.put("row", rowNum);
                    errorDetails.put("error", e.getMessage());
                    errors.add(errorDetails);
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to process Excel file: " + e.getMessage(), e);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("totalRows", totalRows);
        response.put("successfulRows", successfulRows);
        response.put("failedRows", failedRows);
        response.put("errors", errors);
        return response;
    }

    private String getCellValueAsString(Cell cell) {
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> {
                if (DateUtil.isCellDateFormatted(cell)) {
                    yield cell.getLocalDateTimeCellValue().toLocalDate().toString();
                } else {
                    yield String.valueOf((long) cell.getNumericCellValue());
                }
            }
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default -> null;
        };
    }

    @Transactional
    public List<EmployeeEntity> importEmployeesBatch(List<EmployeeEntity> employees, String mode) {
        List<EmployeeEntity> savedList = new ArrayList<>();
        for (EmployeeEntity emp : employees) {
            if (emp.getCode() == null || emp.getCode().isBlank()) {
                emp.setCode("EMP" + UUID.randomUUID().toString().substring(0, 6).toUpperCase());
            }
            if (emp.getId() == null || emp.getId().isBlank()) {
                emp.setId("EMP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
            }
            if (emp.getName() == null || emp.getName().isBlank()) {
                emp.setName("Unnamed Employee");
            }
            if (emp.getDepartment() == null || emp.getDepartment().isBlank()) {
                emp.setDepartment("Engineering");
            }
            if (emp.getDesignation() == null || emp.getDesignation().isBlank()) {
                emp.setDesignation("Staff");
            }
            if (emp.getType() == null || emp.getType().isBlank()) {
                emp.setType("office");
            }
            if (emp.getStatus() == null || emp.getStatus().isBlank()) {
                emp.setStatus("active");
            }
            if (emp.getJoiningDate() == null) {
                emp.setJoiningDate(LocalDate.now());
            }

            Optional<EmployeeEntity> existingOpt = employeeRepository.findByCodeIgnoreCase(emp.getCode());
            if (existingOpt.isEmpty() && emp.getId() != null) {
                existingOpt = employeeRepository.findById(emp.getId());
            }

            if (existingOpt.isPresent()) {
                if ("skipExisting".equalsIgnoreCase(mode)) {
                    continue;
                }
                EmployeeEntity existing = existingOpt.get();
                existing.setName(emp.getName());
                if (emp.getEmail() != null) existing.setEmail(emp.getEmail());
                if (emp.getPhone() != null) existing.setPhone(emp.getPhone());
                if (emp.getDepartment() != null) existing.setDepartment(emp.getDepartment());
                if (emp.getDesignation() != null) existing.setDesignation(emp.getDesignation());
                if (emp.getType() != null) existing.setType(emp.getType());
                if (emp.getStatus() != null) existing.setStatus(emp.getStatus());
                if (emp.getJoiningDate() != null) existing.setJoiningDate(emp.getJoiningDate());
                if (emp.getMonthlyCtc() != null) existing.setMonthlyCtc(emp.getMonthlyCtc());
                if (emp.getBasicSalary() != null) existing.setBasicSalary(emp.getBasicSalary());
                if (emp.getSalary() != null) existing.setSalary(emp.getSalary());
                savedList.add(employeeRepository.save(existing));
            } else {
                savedList.add(createEmployee(emp));
            }
        }
        return savedList;
    }

    public void toggleStatus(String id) {
        employeeRepository.findById(id).ifPresent(emp -> {
            emp.setStatus("active".equalsIgnoreCase(emp.getStatus()) ? "inactive" : "active");
            employeeRepository.save(emp);
        });
    }

    public void deleteAllEmployees() {
        employeeRepository.deleteAll();
    }
}
