package com.freelance.payroll.service;

import com.freelance.payroll.dto.AuthResponse;
import com.freelance.payroll.dto.GoogleAuthRequest;
import com.freelance.payroll.dto.LoginRequest;
import com.freelance.payroll.entity.AuditLogEntity;
import com.freelance.payroll.entity.EmployeeEntity;
import com.freelance.payroll.entity.UserEntity;
import com.freelance.payroll.exception.ForbiddenException;
import com.freelance.payroll.exception.UnauthorizedException;
import com.freelance.payroll.repository.AuditLogRepository;
import com.freelance.payroll.repository.EmployeeRepository;
import com.freelance.payroll.repository.UserRepository;
import com.freelance.payroll.security.JwtService;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final EmployeeRepository employeeRepository;
    private final AuditLogRepository auditLogRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Value("${google.oauth.client-id:}")
    private String googleClientId;

    @Value("${google.oauth.verify-token:true}")
    private boolean verifyToken;

    @Autowired
    public AuthService(
            UserRepository userRepository,
            EmployeeRepository employeeRepository,
            AuditLogRepository auditLogRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {
        this.userRepository = userRepository;
        this.employeeRepository = employeeRepository;
        this.auditLogRepository = auditLogRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        String input = request.getEffectiveUsername();
        String rawPassword = request.getPassword() != null ? request.getPassword().trim() : "";

        if (input.isEmpty() || rawPassword.isEmpty()) {
            throw new IllegalArgumentException("Username/email and password are required.");
        }

        // 1. Check direct match in users table by username, email, or employeeId
        Optional<UserEntity> userOpt = userRepository.findByUsernameIgnoreCase(input);
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByEmailIgnoreCase(input);
        }
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByEmployeeId(input);
        }

        // 2. Check employees table by code, email, id, or phone
        Optional<EmployeeEntity> empOpt = employeeRepository.findByCodeIgnoreCase(input);
        if (empOpt.isEmpty()) {
            empOpt = employeeRepository.findByEmailIgnoreCase(input);
        }
        if (empOpt.isEmpty()) {
            empOpt = employeeRepository.findById(input);
        }
        if (empOpt.isEmpty() && input.replaceAll("[^0-9]", "").length() >= 10) {
            empOpt = employeeRepository.findByPhone(input);
        }

        if (empOpt.isPresent()) {
            EmployeeEntity emp = empOpt.get();
            if (userOpt.isEmpty()) {
                userOpt = userRepository.findByEmployeeId(emp.getId());
            }
            if (userOpt.isEmpty() && emp.getEmail() != null && !emp.getEmail().isBlank()) {
                userOpt = userRepository.findByEmailIgnoreCase(emp.getEmail());
            }
            if (userOpt.isEmpty() && emp.getCode() != null) {
                userOpt = userRepository.findByUsernameIgnoreCase(emp.getCode());
            }

            // Auto-provision user account if needed
            if (userOpt.isEmpty()) {
                String role = "field".equalsIgnoreCase(emp.getType()) ? "fieldStaff" : "hr";
                UserEntity newUser = UserEntity.builder()
                        .id("USER-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                        .username(emp.getCode() != null ? emp.getCode() : emp.getEmail())
                        .email(emp.getEmail() != null && !emp.getEmail().isBlank() ? emp.getEmail().toLowerCase().trim() : input.toLowerCase())
                        .password(passwordEncoder.encode(rawPassword))
                        .name(emp.getName())
                        .role(role)
                        .employeeId(emp.getId())
                        .department(emp.getDepartment())
                        .avatarUrl(emp.getAvatarUrl())
                        .active(true)
                        .build();
                userOpt = Optional.of(userRepository.save(newUser));
            } else {
                UserEntity existingUser = userOpt.get();
                boolean changed = false;
                if (existingUser.getEmployeeId() == null) {
                    existingUser.setEmployeeId(emp.getId());
                    changed = true;
                }
                if (existingUser.getUsername() == null || existingUser.getUsername().isBlank()) {
                    existingUser.setUsername(emp.getCode());
                    changed = true;
                }
                if (changed) {
                    userRepository.save(existingUser);
                }
            }
        }

        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("Invalid credentials. Account not found in employee records.");
        }

        UserEntity user = userOpt.get();
        if (Boolean.FALSE.equals(user.getActive())) {
            recordAuditLog("ACCOUNT_DISABLED_LOGIN_ATTEMPT", user.getName(), user.getRole(), "Disabled user attempted password login: " + input);
            throw new ForbiddenException("User account is inactive. Please contact your administrator.");
        }

        // Password verification (support BCrypt, fallback to plaintext upgrade if legacy)
        boolean passwordMatches = passwordEncoder.matches(rawPassword, user.getPassword());
        if (!passwordMatches && user.getPassword() != null && user.getPassword().equals(rawPassword)) {
            user.setPassword(passwordEncoder.encode(rawPassword));
            userRepository.save(user);
            passwordMatches = true;
        }

        if (!passwordMatches) {
            throw new IllegalArgumentException("Invalid credentials. Incorrect password.");
        }

        // Normalize role for client
        String normalizedRole = user.getRole();
        if ("FIELD_STAFF".equalsIgnoreCase(normalizedRole) || "field_staff".equalsIgnoreCase(normalizedRole)) {
            normalizedRole = "fieldStaff";
        } else if ("ADMIN".equalsIgnoreCase(normalizedRole)) {
            normalizedRole = "admin";
        } else if ("HR".equalsIgnoreCase(normalizedRole)) {
            normalizedRole = "hr";
        }
        user.setRole(normalizedRole);

        // Generate JWT tokens
        String token = jwtService.generateToken(user.getEmail(), normalizedRole, user.getName(), user.getEmployeeId());
        String refreshToken = jwtService.generateRefreshToken(user.getEmail());

        user.setToken(token);
        userRepository.save(user);

        // Audit Log
        recordAuditLog("LOGIN", user.getName(), normalizedRole, "User logged in successfully via username/email: " + input);

        return AuthResponse.builder()
                .id(user.getId())
                .username(user.getUsername() != null ? user.getUsername() : user.getEmail())
                .email(user.getEmail())
                .name(user.getName())
                .role(normalizedRole)
                .employeeId(user.getEmployeeId())
                .department(user.getDepartment())
                .avatarUrl(user.getAvatarUrl())
                .token(token)
                .refreshToken(refreshToken)
                .build();
    }

    @Transactional
    public AuthResponse refreshToken(String refreshToken) {
        if (refreshToken == null || !jwtService.validateToken(refreshToken)) {
            throw new IllegalArgumentException("Invalid or expired refresh token.");
        }

        String username = jwtService.extractUsername(refreshToken);
        Optional<UserEntity> userOpt = userRepository.findByEmailIgnoreCase(username);
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByUsernameIgnoreCase(username);
        }

        UserEntity user = userOpt.orElseThrow(() -> new IllegalArgumentException("User not found for refresh token."));

        String newToken = jwtService.generateToken(user.getEmail(), user.getRole(), user.getName(), user.getEmployeeId());
        user.setToken(newToken);
        userRepository.save(user);

        return AuthResponse.builder()
                .id(user.getId())
                .username(user.getUsername() != null ? user.getUsername() : user.getEmail())
                .email(user.getEmail())
                .name(user.getName())
                .role(user.getRole())
                .employeeId(user.getEmployeeId())
                .department(user.getDepartment())
                .avatarUrl(user.getAvatarUrl())
                .token(newToken)
                .refreshToken(refreshToken)
                .build();
    }

    @Transactional
    public void logout(String token) {
        if (token != null) {
            try {
                String username = jwtService.extractUsername(token);
                userRepository.findByEmailIgnoreCase(username).ifPresent(user -> {
                    user.setToken(null);
                    userRepository.save(user);
                });
            } catch (Exception ignored) {}
        }
    }

    @Transactional
    public AuthResponse signInWithGoogle(GoogleAuthRequest request) {
        if (request == null) {
            throw new UnauthorizedException("Google authentication request cannot be null.");
        }
        String tokenStr = request.getEffectiveToken();
        if (tokenStr == null || tokenStr.trim().isEmpty()) {
            throw new UnauthorizedException("Google ID Token is required");
        }

        String email = null;
        String name = null;
        String googleSubjectId = null;
        String avatarUrl = null;

        if (verifyToken) {
            try {
                GoogleIdTokenVerifier.Builder verifierBuilder = new GoogleIdTokenVerifier.Builder(
                        GoogleNetHttpTransport.newTrustedTransport(),
                        GsonFactory.getDefaultInstance()
                );

                if (googleClientId != null && !googleClientId.isBlank()) {
                    verifierBuilder.setAudience(Collections.singletonList(googleClientId.trim()));
                }

                GoogleIdTokenVerifier verifier = verifierBuilder.build();
                GoogleIdToken idToken = verifier.verify(tokenStr);

                if (idToken == null) {
                    log.warn("Google ID token verification failed. Signature, expiration or audience mismatch.");
                    recordAuditLog("GOOGLE_LOGIN_FAILED", "UNKNOWN", "ANONYMOUS", "Google token verification failed for token");
                    throw new UnauthorizedException("Google authentication failed: Invalid or expired Google ID token.");
                }

                GoogleIdToken.Payload payload = idToken.getPayload();
                googleSubjectId = payload.getSubject();
                email = payload.getEmail();
                Boolean emailVerified = payload.getEmailVerified();
                name = (String) payload.get("name");
                avatarUrl = (String) payload.get("picture");

                if (email == null || email.trim().isEmpty()) {
                    throw new UnauthorizedException("Google authentication failed: Email claim missing from ID token.");
                }

                if (Boolean.FALSE.equals(emailVerified)) {
                    throw new UnauthorizedException("Google authentication failed: Google account email is not verified.");
                }
            } catch (UnauthorizedException ue) {
                throw ue;
            } catch (Exception e) {
                log.error("Exception during Google ID token verification: {}", e.getMessage(), e);
                recordAuditLog("GOOGLE_LOGIN_FAILED", "UNKNOWN", "ANONYMOUS", "Error during Google token verification: " + e.getMessage());
                throw new UnauthorizedException("Google authentication error: " + e.getMessage());
            }
        } else {
            email = request.getEmail();
            name = request.getName();
            googleSubjectId = request.getGoogleId();
            avatarUrl = request.getPhotoUrl();
        }

        if (email == null || email.trim().isEmpty()) {
            throw new UnauthorizedException("Email could not be determined from Google Sign-In");
        }

        String finalEmail = email.trim().toLowerCase();

        // 1. Query PostgreSQL for user by Google Subject ID or email
        Optional<UserEntity> userOpt = Optional.empty();
        if (googleSubjectId != null && !googleSubjectId.isBlank()) {
            userOpt = userRepository.findByGoogleSubjectId(googleSubjectId);
        }
        if (userOpt.isEmpty()) {
            userOpt = userRepository.findByEmailIgnoreCase(finalEmail);
        }

        UserEntity user;
        if (userOpt.isPresent()) {
            user = userOpt.get();
            if (Boolean.FALSE.equals(user.getActive())) {
                recordAuditLog("ACCOUNT_DISABLED_LOGIN_ATTEMPT", user.getName(), user.getRole(), "Disabled user attempted Google login: " + finalEmail);
                throw new ForbiddenException("Your account has been disabled. Please contact the administrator.");
            }
            if (user.getGoogleSubjectId() == null && googleSubjectId != null) {
                user.setGoogleSubjectId(googleSubjectId);
            }
            if ((user.getAvatarUrl() == null || user.getAvatarUrl().isBlank()) && avatarUrl != null) {
                user.setAvatarUrl(avatarUrl);
            }
            if (user.getAuthProvider() == null || user.getAuthProvider().isBlank()) {
                user.setAuthProvider("GOOGLE");
            }
        } else {
            // 2. Check employees table for pre-registered employee profile
            Optional<EmployeeEntity> empOpt = employeeRepository.findByEmailIgnoreCase(finalEmail);
            if (empOpt.isPresent()) {
                EmployeeEntity emp = empOpt.get();
                if ("inactive".equalsIgnoreCase(emp.getStatus())) {
                    recordAuditLog("ACCOUNT_DISABLED_LOGIN_ATTEMPT", emp.getName(), "EMPLOYEE", "Inactive employee attempted Google login: " + finalEmail);
                    throw new ForbiddenException("Your employee account is inactive. Please contact HR administration.");
                }

                String role = "field".equalsIgnoreCase(emp.getType()) ? "FIELD_STAFF" : "HR";
                user = UserEntity.builder()
                        .id("USER-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                        .username(emp.getCode() != null ? emp.getCode() : finalEmail)
                        .email(finalEmail)
                        .name(emp.getName() != null ? emp.getName() : (name != null ? name : "Google User"))
                        .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                        .role(role)
                        .employeeId(emp.getId())
                        .department(emp.getDepartment())
                        .avatarUrl(avatarUrl != null ? avatarUrl : emp.getAvatarUrl())
                        .googleSubjectId(googleSubjectId)
                        .authProvider("GOOGLE")
                        .active(true)
                        .build();
                user = userRepository.save(user);
            } else {
                // Reject unregistered Google accounts
                recordAuditLog("GOOGLE_ACCOUNT_NOT_REGISTERED", name != null ? name : "Unknown", "GUEST", "Unregistered Google account attempted login: " + finalEmail);
                throw new ForbiddenException("Your Google account (" + finalEmail + ") is not registered. Please contact the administrator to set up your account.");
            }
        }

        // Generate application JWT and refresh token
        String token = jwtService.generateToken(user.getEmail(), user.getRole(), user.getName(), user.getEmployeeId());
        String refreshToken = jwtService.generateRefreshToken(user.getEmail());
        user.setToken(token);
        userRepository.save(user);

        // Audit Log
        recordAuditLog("GOOGLE_LOGIN_SUCCESS", user.getName(), user.getRole(), "User logged in successfully via Google Sign-In: " + finalEmail);

        return AuthResponse.builder()
                .id(user.getId())
                .username(user.getUsername() != null ? user.getUsername() : user.getEmail())
                .email(user.getEmail())
                .name(user.getName())
                .role(user.getRole())
                .employeeId(user.getEmployeeId())
                .department(user.getDepartment())
                .avatarUrl(user.getAvatarUrl())
                .token(token)
                .refreshToken(refreshToken)
                .build();
    }

    public Optional<AuthResponse> getCurrentUser(String token) {
        if (token == null || !jwtService.validateToken(token)) {
            return Optional.empty();
        }
        try {
            String username = jwtService.extractUsername(token);
            Optional<UserEntity> userOpt = userRepository.findByEmailIgnoreCase(username);
            if (userOpt.isEmpty()) {
                userOpt = userRepository.findByUsernameIgnoreCase(username);
            }
            return userOpt.map(u -> AuthResponse.builder()
                    .id(u.getId())
                    .username(u.getUsername())
                    .email(u.getEmail())
                    .name(u.getName())
                    .role(u.getRole())
                    .employeeId(u.getEmployeeId())
                    .department(u.getDepartment())
                    .avatarUrl(u.getAvatarUrl())
                    .token(token)
                    .build());
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    private void recordAuditLog(String action, String actorName, String actorRole, String details) {
        try {
            auditLogRepository.save(AuditLogEntity.builder()
                    .id("AUD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                    .action(action)
                    .actorName(actorName)
                    .actorRole(actorRole)
                    .targetEntity("USER")
                    .details(details)
                    .timestamp(LocalDateTime.now())
                    .build());
        } catch (Exception e) {
            log.warn("Failed to write audit log: {}", e.getMessage());
        }
    }
}
