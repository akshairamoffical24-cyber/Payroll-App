package com.freelance.payroll.controller;

import com.freelance.payroll.dto.ApiResponse;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.service.EmployeeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {

    private final EmployeeService employeeService;

    @Autowired
    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<EmployeeEntity>>> getAllEmployees() {
        return ResponseEntity.ok(ApiResponse.success(employeeService.getAllEmployees()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EmployeeEntity>> getEmployeeById(@PathVariable String id) {
        return employeeService.getEmployeeById(id)
                .map(e -> ResponseEntity.ok(ApiResponse.success(e)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<EmployeeEntity>> createEmployee(@RequestBody EmployeeEntity employee) {
        EmployeeEntity created = employeeService.createEmployee(employee);
        return ResponseEntity.ok(ApiResponse.success("Employee created successfully", created));
    }

    @PostMapping("/import")
    public ResponseEntity<ApiResponse<List<EmployeeEntity>>> importEmployees(@RequestBody com.freelance.payroll.dto.EmployeeImportRequest request) {
        List<EmployeeEntity> imported = employeeService.importEmployees(request.getMode(), request.getEmployees());
        return ResponseEntity.ok(ApiResponse.success("Employees imported successfully", imported));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<EmployeeEntity>> updateEmployee(@PathVariable String id, @RequestBody EmployeeEntity employee) {
        EmployeeEntity updated = employeeService.updateEmployee(id, employee);
        return ResponseEntity.ok(ApiResponse.success("Employee updated successfully", updated));
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
