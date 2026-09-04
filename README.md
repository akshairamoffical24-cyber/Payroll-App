# Payroll & Attendance Management System (WorkPulse)

A full-stack, enterprise-grade Payroll and Geofenced Attendance Management platform built with **Flutter**, **Spring Boot 3 / Java 21**, **PostgreSQL**, **Spring Security + JWT + BCrypt**, and **Apache POI**.

---

## 1. Architecture Overview

```
Flutter Client (Web, Android Emulator, iOS, Desktop)
    │
    │  (Dio HTTP Client + Auth Interceptors + Platform Base URL)
    ▼
Spring Boot REST Backend (Port 8080)
    │
    ├── Spring Security & JWT Filter (Stateless, BCrypt Hashing)
    ├── REST Controllers (Auth, Employees, Sites, Attendance, Leaves, Payroll, Dashboard, Reports, Audit)
    ├── Business Service Layer (Haversine Geofencing, Payroll Calculation Engine, Excel Parser)
    └── Spring Data JPA / Hibernate
            │
            ▼
PostgreSQL Database (`payroll_attendance`)
```

> **Security Rule**: Flutter never connects directly to PostgreSQL. All transactions, access control, geofence validation, and salary calculations are strictly processed and validated on the Spring Boot backend.

---

## 2. Technology Stack

- **Frontend**: Flutter 3.x / Dart 3 (Flutter Riverpod, GoRouter, Dio, FlChart, FlutterMap, Printing/PDF, Excel)
- **Backend**: Spring Boot 3 / 4 (Java 21)
- **Database**: PostgreSQL 14+ (`payroll_attendance`)
- **ORM / Persistence**: Spring Data JPA + Hibernate with connection pooling (HikariCP)
- **Security**: Spring Security 6, JJWT (0.12.6), BCrypt Password Encoder
- **Excel Processing**: Apache POI (5.3.0) for `.xlsx` import and export
- **API Testing**: Postman Collection & Environment (`postman/`)

---

## 3. Database Setup & PostgreSQL Installation

### 3.1 PostgreSQL Installation
1. Install PostgreSQL from [official PostgreSQL download](https://www.postgresql.org/download/).
2. Start the PostgreSQL service on `localhost:5432`.

### 3.2 Create Database
Open `psql` or pgAdmin and run:

```sql
CREATE DATABASE payroll_attendance;
```

---

## 4. Environment Variables & Configuration

Create a `.env` file or export environment variables:

| Variable Name | Default Value | Description |
|---|---|---|
| `DB_URL` | `jdbc:postgresql://localhost:5432/payroll_attendance` | PostgreSQL JDBC connection URL |
| `DB_USERNAME` | `postgres` | Database username |
| `DB_PASSWORD` | `AKSHAIRAM@2007` | Database password |
| `JWT_SECRET` | `WorkPulseSecureJwtSecretKeyForPayrollAttendanceSystem2026!` | Minimum 256-bit HMAC secret |
| `JWT_EXPIRATION_MS` | `86400000` (24h) | Access token expiration |
| `JWT_REFRESH_EXPIRATION_MS` | `604800000` (7 days) | Refresh token expiration |
| `GOOGLE_CLIENT_ID` | `857844766578-p6p5m390fcm2jjjkorirebub1fq6jb96...` | Google OAuth Client ID |

See [`.env.example`](file:///d:/Payroll%20staff%20attendance/.env.example) for a complete template.

---

## 5. Google OAuth 2.0 Authentication Setup

### 5.1 Architecture & Flow
```
User clicks "Sign in with Google" (Flutter Web / Mobile)
     │
     ▼
Google Identity Services opens OAuth popup
     │
     ▼
Google returns verified ID Token (JWT signed by Google)
     │
     ▼
POST /api/auth/google  { "credential": "<GOOGLE_ID_TOKEN>" }
     │
     ▼
Spring Boot Backend (`GoogleIdTokenVerifier`):
  • Cryptographically verifies RSA signature with Google public keys
  • Validates issuer (`accounts.google.com`) and audience (`GOOGLE_CLIENT_ID`)
  • Verifies token expiration and verified email claim
     │
     ▼
PostgreSQL Database:
  • Searches `users` table by `googleSubjectId` or `email`
  • If existing user: checks `active` status & retrieves role from DB
  • If new: checks `employees` table for registered employee profile
  • Rejects unregistered accounts (never auto-assigns ADMIN or HR)
     │
     ▼
Spring Boot generates Application JWT & Refresh Token
     │
     ▼
Flutter stores authenticated session in Riverpod & navigates by role:
  • ADMIN / HR ➔ `/dashboard`
  • FIELD_STAFF / EMPLOYEE ➔ `/field-dashboard`
```

### 5.2 Google Cloud Console Configuration
1. Open [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials).
2. Configure your **OAuth Consent Screen** (User Type: External or Internal). Add scopes: `.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`.
3. Create **OAuth 2.0 Client ID**:
   - Application type: **Web application**
   - Name: `WorkPulse Attendance Platform`
   - **Authorized JavaScript origins**:
     - `http://localhost`
     - `http://localhost:7357` (Flutter Web port)
     - `http://localhost:8080` (Spring Boot API port)
     - `https://your-production-domain.com`
   - **Authorized redirect URIs**:
     - `http://localhost:7357`
     - `http://localhost:8080/login/oauth2/code/google`
     - `https://your-production-domain.com`
4. Copy your **Client ID** (e.g. `857844766578-p6p5m390fcm2jjjkorirebub1fq6jb96.apps.googleusercontent.com`).

### 5.3 Frontend & Backend Configuration
- **Backend (`application.properties` or `.env`)**:
  ```properties
  google.oauth.client-id=857844766578-p6p5m390fcm2jjjkorirebub1fq6jb96.apps.googleusercontent.com
  google.oauth.verify-token=true
  ```
- **Flutter Web (`flutter_application_1/web/index.html`)**:
  ```html
  <meta name="google-signin-client_id" content="857844766578-p6p5m390fcm2jjjkorirebub1fq6jb96.apps.googleusercontent.com">
  ```
- **Flutter Config (`flutter_application_1/lib/core/config/auth_config.dart`)**:
  ```dart
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '857844766578-p6p5m390fcm2jjjkorirebub1fq6jb96.apps.googleusercontent.com',
  );
  ```

### 5.4 Troubleshooting Common Issues
| Error | Cause | Resolution |
|---|---|---|
| `redirect_uri_mismatch` / `origin_mismatch` | Current port not listed in Google Console | Add `http://localhost:7357` to Authorized JavaScript Origins in Google Cloud Console. |
| `401 Unauthorized: Invalid Google ID token` | Token expired, forged, or client ID mismatch | Ensure frontend and backend use the exact same Google Client ID. |
| `403 Forbidden: Google account is not registered` | Email authenticated with Google but not in PostgreSQL | Register the employee or user in PostgreSQL first. |
| `403 Forbidden: Account disabled` | User `active` flag is set to `false` in DB | Reactivate user via Admin/HR panel. |

---

## 5. Running the Application

### 5.1 Start Spring Boot Backend
From the root workspace:

```bash
cd backend
.\mvnw.cmd spring-boot:run
```
The server will start on `http://localhost:8080` and automatically seed default admin accounts and master sites on first boot.

#### Default Seed Accounts:
- **Admin**: `admin@workpulse.com` / `admin123` (or username `admin`)
- **HR**: `hr@workpulse.com` / `hr123` (or username `hr`)
- **Field Staff**: `field@workpulse.com` / `field123` (or username `field`)

### 5.2 Start Flutter Frontend
From the root workspace:

```bash
cd flutter_application_1
flutter run -d chrome --web-port=7357
```
Or for Android emulator / Windows desktop:
```bash
flutter run -d windows
flutter run -d android
```

---

## 6. Android Emulator Networking
Inside the standard Android Emulator:
- `localhost` refers to the Android device itself.
- To access the Spring Boot backend running on your host development machine, the Flutter app dynamically uses:
  ```
  http://10.0.2.2:8080/api
  ```
- For Web / Windows / macOS / Linux desktop, the client connects to:
  ```
  http://localhost:8080/api
  ```

---

## 7. REST API Reference

### 7.1 Authentication (`/api/auth`)
- `POST /api/auth/login`: Authenticate with username/email and password. Returns JWT token.
- `POST /api/auth/refresh`: Refresh expired access token using `refreshToken`.
- `POST /api/auth/logout`: Invalidate user session token.
- `GET /api/auth/me`: Get current authenticated user details.
- `POST /api/auth/google`: Sign in with verified Google ID token.

### 7.2 Employees (`/api/employees`)
- `GET /api/employees`: Paginated list of employees (`?page=0&size=20`).
- `GET /api/employees/{id}`: Get employee by ID.
- `POST /api/employees`: Create new employee with auto-created user credentials.
- `PUT /api/employees/{id}`: Update employee details.
- `DELETE /api/employees/{id}`: Delete employee (Admin only).
- `GET /api/employees/search?name=Akshai`: Search employees by name, code, or email.
- `GET /api/employees/department/{department}`: Filter by department.
- `POST /api/employees/import`: Upload Excel `.xlsx` sheet (multipart) with row-by-row validation.
- `GET /api/employees/export`: Download all employees as `.xlsx`.

### 7.3 Sites & Geofencing (`/api/sites`)
- `GET /api/sites`: List all sites.
- `GET /api/sites/{id}`: Get site details.
- `POST /api/sites`: Create site with GPS latitude, longitude, and geofence radius in meters.
- `PUT /api/sites/{id}`: Update site coordinates or radius.
- `DELETE /api/sites/{id}`: Delete site (Admin only).

### 7.4 Site Mappings (`/api/site-mappings` or `/api/mappings`)
- `GET /api/site-mappings`: List all employee-site mappings.
- `GET /api/site-mappings/employee/{employeeId}`: List assigned sites for an employee.
- `POST /api/site-mappings`: Assign employee to sites with validity date range.
- `DELETE /api/site-mappings/{id}`: Remove mapping.

### 7.5 Attendance & GPS Geofencing (`/api/attendance`)
- `POST /api/attendance/check-in`: Validates employee coordinates against assigned site using Haversine formula. Rejects with `"Employee is outside the permitted site geofence."` if out of bounds.
- `POST /api/attendance/check-out`: Verifies open attendance, records checkout timestamp, and calculates working hours.
- `GET /api/attendance/today`: View today's attendance summary.
- `GET /api/attendance/range?from=YYYY-MM-DD&to=YYYY-MM-DD`: Date-range attendance log.
- `GET /api/attendance/employee/{employeeId}`: Employee attendance history.

### 7.6 Leave Management (`/api/leaves`)
- `POST /api/leaves`: Submit a leave request.
- `GET /api/leaves`: List all leave requests.
- `GET /api/leaves/pending`: List pending leave requests awaiting approval.
- `PUT /api/leaves/{id}/approve`: Approve leave request (HR/Admin).
- `PUT /api/leaves/{id}/reject`: Reject leave request (HR/Admin).

### 7.7 Payroll (`/api/payroll`)
- `POST /api/payroll/generate`: Generate monthly payroll calculation (Gross CTC, per-day salary, payable days, PF, ESI, Professional Tax, Net Salary).
- `GET /api/payroll`: View all generated payroll records (or `?month=8&year=2026`).
- `GET /api/payroll/{id}`: View payroll record by ID.
- `GET /api/payroll/{id}/items`: View itemized breakdown (Basic, HRA, Special Allowance, PF, ESI, Tax).
- `GET /api/payroll/employee/{employeeId}`: Employee salary slips.

### 7.8 Dashboard & Reports (`/api/dashboard` & `/api/reports`)
- `GET /api/dashboard/admin`: Command center metrics (total, present, late, on leave, absent, sites, pending leaves, payroll summary).
- `GET /api/dashboard/hr`: HR operational dashboard metrics.
- `GET /api/reports/attendance`: Attendance audit report with date filters.
- `GET /api/reports/payroll`: Monthly payroll cost and disbursement report.
- `GET /api/reports/employee`: Workforce distribution report by department.
- `GET /api/reports/leave`: Leave balance and utilization report.

### 7.9 Biometrics & Face (`/api/face`)
- `POST /api/face/register`: Secure biometric template vector registration.
- `GET /api/face/{employeeId}`: Biometric status lookup.
- `DELETE /api/face/{employeeId}`: Revoke face registration.

### 7.10 Audit Logs (`/api/audit-logs`)
- `GET /api/audit-logs`: Immutable trail of logins, CRUD operations, geofence check-ins, leave approvals, and payroll executions.

---

## 8. Postman Testing

Import the collection and environment files into Postman:
1. Collection: [`postman/Payroll_Attendance_API.postman_collection.json`](file:///d:/Payroll%20staff%20attendance/postman/Payroll_Attendance_API.postman_collection.json)
2. Environment: [`postman/Payroll_Attendance_Local.postman_environment.json`](file:///d:/Payroll%20staff%20attendance/postman/Payroll_Attendance_Local.postman_environment.json)

Set `{{baseUrl}}` to `http://localhost:8080/api`.
Execute **Login** with `admin@workpulse.com` / `admin123`. The test script automatically saves `{{authToken}}` and passes `Authorization: Bearer {{authToken}}` to subsequent requests.

---

## 9. Running Tests

To run the automated backend test suite:

```bash
cd backend
.\mvnw.cmd test
```

To run static analysis on the Flutter application:

```bash
cd flutter_application_1
flutter analyze
```

---

## 10. Database Troubleshooting
- **Connection Refused (`5432`)**: Verify PostgreSQL service is running:
  - Windows: `Get-Service -Name postgresql* | Start-Service`
  - Linux/Mac: `sudo systemctl start postgresql`
- **Database Does Not Exist**:
  - Run `psql -U postgres -c "CREATE DATABASE payroll_attendance;"`
- **Password Authentication Failed**:
  - Update `DB_PASSWORD` in `.env` or `application.properties` to match your local postgres superuser password.
