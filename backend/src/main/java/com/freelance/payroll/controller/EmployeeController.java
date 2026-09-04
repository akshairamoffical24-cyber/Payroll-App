package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.dto.EmployeeBatchImportRequest;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.service.EmployeeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {

    private final EmployeeService employeeService;

    @Autowired
    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Object>> getEmployees(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        if (page != null && size != null) {
            Pageable pageable = PageRequest.of(page, size, Sort.by("name").ascending());
            Page<EmployeeEntity> employeePage = employeeService.getEmployees(pageable);
            return ResponseEntity.ok(ApiResponse.success(employeePage));
        }
        return ResponseEntity.ok(ApiResponse.success(employeeService.getAllEmployees()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EmployeeEntity>> getEmployeeById(@PathVariable String id) {
        return employeeService.getEmployeeById(id)
                .map(e -> ResponseEntity.ok(ApiResponse.success(e)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<EmployeeEntity>>> searchEmployees(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String query) {
        String searchTerm = name != null ? name : query;
        List<EmployeeEntity> results = employeeService.searchEmployees(searchTerm);
        return ResponseEntity.ok(ApiResponse.success(results));
    }

    @GetMapping("/department/{department}")
    public ResponseEntity<ApiResponse<List<EmployeeEntity>>> getEmployeesByDepartment(@PathVariable String department) {
        List<EmployeeEntity> results = employeeService.getEmployeesByDepartment(department);
        return ResponseEntity.ok(ApiResponse.success(results));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<EmployeeEntity>> createEmployee(@RequestBody EmployeeEntity employee) {
        EmployeeEntity created = employeeService.createEmployee(employee);
        return ResponseEntity.ok(ApiResponse.success("Employee created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<EmployeeEntity>> updateEmployee(@PathVariable String id, @RequestBody EmployeeEntity employee) {
        EmployeeEntity updated = employeeService.updateEmployee(id, employee);
        return ResponseEntity.ok(ApiResponse.success("Employee updated successfully", updated));
    }

    @PostMapping(value = "/import", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<List<EmployeeEntity>>> importEmployeesJson(@RequestBody EmployeeBatchImportRequest request) {
        List<EmployeeEntity> employees = request != null && request.getEmployees() != null ? request.getEmployees() : List.of();
        String mode = request != null && request.getMode() != null ? request.getMode() : "addNew";
        List<EmployeeEntity> result = employeeService.importEmployeesBatch(employees, mode);
        return ResponseEntity.ok(ApiResponse.success("Employees imported successfully", result));
    }

    @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Map<String, Object>>> importEmployeesFromExcel(@RequestParam("file") MultipartFile file) {
        Map<String, Object> result = employeeService.importEmployeesFromExcel(file);
        return ResponseEntity.ok(ApiResponse.success("Excel processed successfully", result));
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportEmployeesToExcel() {
        byte[] excelBytes = employeeService.exportEmployeesToExcel();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=employees.xlsx")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(excelBytes);
    }

    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Void>> toggleStatus(@PathVariable String id) {
        employeeService.toggleStatus(id);
        return ResponseEntity.ok(ApiResponse.success("Employee status toggled", null));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteEmployee(@PathVariable String id) {
        employeeService.deleteEmployee(id);
        return ResponseEntity.ok(ApiResponse.success("Employee deleted successfully", null));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> deleteAllEmployees() {
        employeeService.deleteAllEmployees();
        return ResponseEntity.ok(ApiResponse.success("All employees deleted successfully", null));
    }
}
