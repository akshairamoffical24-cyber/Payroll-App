package com.freelance.payroll.repository;

import com.freelance.payroll.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, String> {
    Optional<UserEntity> findByEmailIgnoreCase(String email);
    Optional<UserEntity> findByUsernameIgnoreCase(String username);
    Optional<UserEntity> findByGoogleSubjectId(String googleSubjectId);
    Optional<UserEntity> findByEmployeeId(String employeeId);
    List<UserEntity> findByRoleIgnoreCase(String role);
}
