-- ============================================================================
-- WorkPulse Payroll & Staff Attendance Capture System
-- PostgreSQL Normalized Database Schema DDL
-- Database: payroll_attendance
-- ============================================================================

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL, -- 'admin', 'hr', 'fieldStaff'
    employee_id VARCHAR(64),
    department VARCHAR(128),
    avatar_url VARCHAR(512),
    token VARCHAR(512),
    google_subject_id VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_employee_id ON users(employee_id);

-- 2. EMPLOYEES TABLE
CREATE TABLE IF NOT EXISTS employees (
    id VARCHAR(64) PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    department VARCHAR(128),
    designation VARCHAR(128),
    type VARCHAR(32), -- 'office', 'field'
    phone VARCHAR(32),
    email VARCHAR(255),
    status VARCHAR(32) DEFAULT 'active', -- 'active', 'inactive'
    joining_date DATE,
    work_location VARCHAR(255),
    gender VARCHAR(16),
    portal_access BOOLEAN DEFAULT TRUE,
    epf_enabled BOOLEAN DEFAULT FALSE,
    esi_enabled BOOLEAN DEFAULT FALSE,
    eps_contribution BOOLEAN DEFAULT FALSE,
    professional_tax_enabled BOOLEAN DEFAULT FALSE,
    pf_account_number VARCHAR(64),
    uan VARCHAR(32),
    dob DATE,
    father_name VARCHAR(255),
    address TEXT,
    pan VARCHAR(32),
    differently_abled_type VARCHAR(64),
    payment_mode VARCHAR(32),
    bank_name VARCHAR(128),
    account_number VARCHAR(64),
    ifsc VARCHAR(32),
    account_type VARCHAR(32),
    monthly_ctc NUMERIC(12, 2),
    annual_ctc NUMERIC(12, 2),
    basic_salary NUMERIC(12, 2),
    hra NUMERIC(12, 2),
    special_allowance NUMERIC(12, 2),
    increment_cycle VARCHAR(32),
    increment_percentage NUMERIC(5, 2),
    next_increment_date DATE,
    probation_period_months INT,
    epf_employer_monthly NUMERIC(12, 2),
    epf_employer_annual NUMERIC(12, 2),
    avatar_url VARCHAR(512),
    biometric_id VARCHAR(64),
    is_face_registered BOOLEAN DEFAULT FALSE,
    face_registered_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_employees_code ON employees(code);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);

-- 3. SITES TABLE
CREATE TABLE IF NOT EXISTS sites (
    id VARCHAR(64) PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    client VARCHAR(255),
    project VARCHAR(255),
    address TEXT,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    geofence_radius DECIMAL(10, 2) NOT NULL DEFAULT 100.00,
    po_number VARCHAR(64),
    site_manager_name VARCHAR(255),
    site_engineer_name VARCHAR(255),
    status VARCHAR(32) DEFAULT 'active' -- 'active', 'inactive'
);

CREATE INDEX IF NOT EXISTS idx_sites_code ON sites(code);
CREATE INDEX IF NOT EXISTS idx_sites_status ON sites(status);

-- 4. EMPLOYEE SITE MAPPINGS TABLE
CREATE TABLE IF NOT EXISTS employee_site_mappings (
    id VARCHAR(64) PRIMARY KEY,
    employee_id VARCHAR(64) NOT NULL,
    site_id VARCHAR(64) NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE,
    status VARCHAR(32) DEFAULT 'active', -- 'active', 'inactive', 'expired'
    assigned_by VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mapping_emp ON employee_site_mappings(employee_id);
CREATE INDEX IF NOT EXISTS idx_mapping_site ON employee_site_mappings(site_id);
CREATE INDEX IF NOT EXISTS idx_mapping_status ON employee_site_mappings(status);

-- 5. ATTENDANCE PUNCHES TABLE
CREATE TABLE IF NOT EXISTS attendance_punches (
    id VARCHAR(64) PRIMARY KEY,
    employee_id VARCHAR(64) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    type VARCHAR(32) NOT NULL, -- 'inPunch', 'outPunch', 'visit'
    source VARCHAR(32) NOT NULL, -- 'mobile', 'biometric', 'manual'
    site_id VARCHAR(64),
    site_name VARCHAR(255),
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    accuracy DECIMAL(8, 2),
    distance_meters DECIMAL(10, 2),
    is_verified BOOLEAN DEFAULT TRUE,
    remarks TEXT
);

CREATE INDEX IF NOT EXISTS idx_punches_employee_id ON attendance_punches(employee_id);
CREATE INDEX IF NOT EXISTS idx_punches_timestamp ON attendance_punches(timestamp);
CREATE INDEX IF NOT EXISTS idx_punches_site_id ON attendance_punches(site_id);

-- 6. DAILY ATTENDANCE TABLE
CREATE TABLE IF NOT EXISTS daily_attendance (
    id VARCHAR(64) PRIMARY KEY,
    employee_id VARCHAR(64) NOT NULL,
    date DATE NOT NULL,
    first_punch_id VARCHAR(64),
    first_punch_time TIMESTAMPTZ,
    first_punch_type VARCHAR(32),
    first_punch_source VARCHAR(32),
    first_punch_site_name VARCHAR(255),
    last_punch_id VARCHAR(64),
    last_punch_time TIMESTAMPTZ,
    last_punch_type VARCHAR(32),
    last_punch_source VARCHAR(32),
    last_punch_site_name VARCHAR(255),
    visited_site_names_json TEXT,
    working_minutes BIGINT DEFAULT 0,
    status VARCHAR(32) NOT NULL, -- 'present', 'late', 'absent', 'halfDay', 'leave', etc.
    source_type VARCHAR(32) DEFAULT 'mobile',
    remarks TEXT,
    payroll_working_days_credit NUMERIC(4, 2) DEFAULT 0.0,
    CONSTRAINT uq_emp_attendance_date UNIQUE (employee_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_emp_date ON daily_attendance(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_date ON daily_attendance(date);
CREATE INDEX IF NOT EXISTS idx_daily_status ON daily_attendance(status);

-- 7. FACE REGISTRATIONS TABLE
CREATE TABLE IF NOT EXISTS employee_face_registration (
    id VARCHAR(64) PRIMARY KEY,
    employee_id VARCHAR(64) NOT NULL,
    biometric_template TEXT NOT NULL,
    model_version VARCHAR(32) NOT NULL,
    quality_score DECIMAL(6, 4),
    liveness_score DECIMAL(6, 4),
    registration_status VARCHAR(32) NOT NULL, -- 'ACTIVE', 'REVOKED', 'SUPERSEDED'
    registration_device VARCHAR(64),
    registered_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ,
    registered_by VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_face_emp_status ON employee_face_registration(employee_id, registration_status);

-- 8. EXCEL IMPORTS TABLE
CREATE TABLE IF NOT EXISTS excel_imports (
    id VARCHAR(64) PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    uploaded_by VARCHAR(64),
    uploaded_at TIMESTAMPTZ NOT NULL,
    total_rows INT DEFAULT 0,
    successful_rows INT DEFAULT 0,
    updated_rows INT DEFAULT 0,
    failed_rows INT DEFAULT 0,
    status VARCHAR(32) NOT NULL, -- 'PROCESSING', 'COMPLETED', 'COMPLETED_WITH_ERRORS', 'FAILED'
    error_summary TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_import_status ON excel_imports(status);
CREATE INDEX IF NOT EXISTS idx_import_uploaded_at ON excel_imports(uploaded_at);

-- 9. EXCEL IMPORT ERRORS TABLE
CREATE TABLE IF NOT EXISTS excel_import_errors (
    id VARCHAR(64) PRIMARY KEY,
    import_id VARCHAR(64) NOT NULL,
    row_number INT NOT NULL,
    field_name VARCHAR(64),
    error_message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_import_err_import_id ON excel_import_errors(import_id);

-- 10. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(64) PRIMARY KEY,
    action VARCHAR(64) NOT NULL,
    actor_name VARCHAR(255),
    actor_role VARCHAR(64),
    details TEXT,
    target_entity VARCHAR(255),
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs(action);

-- 11. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    type VARCHAR(32) DEFAULT 'info',
    category VARCHAR(64) DEFAULT 'general',
    action_route VARCHAR(255),
    is_read BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_notif_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notif_timestamp ON notifications(timestamp);

-- 12. REGULARIZATION REQUESTS TABLE
CREATE TABLE IF NOT EXISTS regularization_requests (
    id VARCHAR(64) PRIMARY KEY,
    employee_id VARCHAR(64) NOT NULL,
    request_type VARCHAR(64) NOT NULL,
    reason_category VARCHAR(64),
    attendance_date DATE NOT NULL,
    requested_in_time VARCHAR(32),
    requested_out_time VARCHAR(32),
    remarks TEXT,
    status VARCHAR(32) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    applied_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_by VARCHAR(255),
    reviewed_at TIMESTAMPTZ,
    review_comments TEXT
);

CREATE INDEX IF NOT EXISTS idx_reg_emp ON regularization_requests(employee_id);
CREATE INDEX IF NOT EXISTS idx_reg_status ON regularization_requests(status);

-- 13. PAYROLL RECORDS TABLE
CREATE TABLE IF NOT EXISTS payroll_records (
    id VARCHAR(64) PRIMARY KEY,
    employee_id VARCHAR(64) NOT NULL,
    employee_name VARCHAR(255),
    employee_code VARCHAR(64),
    department VARCHAR(128),
    payroll_month INT,
    payroll_year INT,
    month DATE,
    total_days_in_month INT,
    present_days NUMERIC(5, 2) DEFAULT 0.0,
    paid_leaves NUMERIC(5, 2) DEFAULT 0.0,
    half_days NUMERIC(5, 2) DEFAULT 0.0,
    absent_days NUMERIC(5, 2) DEFAULT 0.0,
    weekly_offs NUMERIC(5, 2) DEFAULT 0.0,
    holidays NUMERIC(5, 2) DEFAULT 0.0,
    payable_days NUMERIC(5, 2) DEFAULT 0.0,
    gross_monthly_ctc NUMERIC(12, 2) DEFAULT 0.0,
    per_day_salary NUMERIC(12, 2) DEFAULT 0.0,
    calculated_payable_salary NUMERIC(12, 2) DEFAULT 0.0,
    deductions NUMERIC(12, 2) DEFAULT 0.0,
    net_payable_salary NUMERIC(12, 2) DEFAULT 0.0,
    status VARCHAR(32) DEFAULT 'draft' -- 'draft', 'processed', 'approved', 'disbursed'
);

CREATE INDEX IF NOT EXISTS idx_payroll_emp_id ON payroll_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_month_year ON payroll_records(payroll_year, payroll_month);

-- 14. SYSTEM SETTINGS TABLE
CREATE TABLE IF NOT EXISTS system_settings (
    id VARCHAR(64) PRIMARY KEY,
    company_name VARCHAR(255),
    office_start_time VARCHAR(32),
    office_end_time VARCHAR(32),
    late_grace_minutes INT DEFAULT 30,
    half_day_threshold_hours INT DEFAULT 4,
    default_geofence_radius_meters DECIMAL(10, 2) DEFAULT 100.00,
    enable_auto_payroll BOOLEAN DEFAULT TRUE,
    enable_biometric_sync BOOLEAN DEFAULT TRUE,
    allow_offline_punches BOOLEAN DEFAULT TRUE,
    max_gps_accuracy_threshold_meters DECIMAL(8, 2) DEFAULT 50.00
);

-- ============================================================================
-- DATABASE VIEWS FOR REPORTING & ANALYTICS
-- ============================================================================

-- View 1: Active Employee Site Mappings
CREATE OR REPLACE VIEW v_active_employee_site_mappings AS
SELECT 
    m.id AS mapping_id,
    e.id AS employee_id,
    e.code AS employee_code,
    e.name AS employee_name,
    e.department AS employee_department,
    s.id AS site_id,
    s.code AS site_code,
    s.name AS site_name,
    s.latitude,
    s.longitude,
    s.geofence_radius,
    m.from_date,
    m.to_date,
    m.status AS mapping_status
FROM employee_site_mappings m
JOIN employees e ON m.employee_id = e.id
JOIN sites s ON m.site_id = s.id
WHERE m.status = 'active'
  AND CURRENT_DATE >= m.from_date
  AND (m.to_date IS NULL OR CURRENT_DATE <= m.to_date);

-- View 2: Daily Attendance Summary with Employee & Site details
CREATE OR REPLACE VIEW v_daily_attendance_summary AS
SELECT 
    da.id AS attendance_id,
    da.date AS attendance_date,
    e.id AS employee_id,
    e.code AS employee_code,
    e.name AS employee_name,
    e.department,
    e.designation,
    e.type AS employee_type,
    da.first_punch_time,
    da.first_punch_site_name,
    da.last_punch_time,
    da.last_punch_site_name,
    da.working_minutes,
    da.status AS attendance_status,
    da.source_type,
    da.payroll_working_days_credit
FROM daily_attendance da
JOIN employees e ON da.employee_id = e.id;

-- View 3: Site-wise Attendance Metrics
CREATE OR REPLACE VIEW v_site_attendance_summary AS
SELECT 
    s.id AS site_id,
    s.name AS site_name,
    s.client AS client_name,
    DATE(ap.timestamp) AS punch_date,
    COUNT(DISTINCT ap.employee_id) AS total_employees_punched,
    COUNT(ap.id) AS total_punches_recorded
FROM sites s
LEFT JOIN attendance_punches ap ON s.id = ap.site_id
GROUP BY s.id, s.name, s.client, DATE(ap.timestamp);

-- View 4: Department-wise Attendance Metrics
CREATE OR REPLACE VIEW v_department_attendance_summary AS
SELECT 
    e.department,
    da.date AS attendance_date,
    COUNT(da.id) AS total_records,
    COUNT(CASE WHEN da.status = 'present' THEN 1 END) AS present_count,
    COUNT(CASE WHEN da.status = 'late' THEN 1 END) AS late_count,
    COUNT(CASE WHEN da.status = 'halfDay' THEN 1 END) AS half_day_count,
    COUNT(CASE WHEN da.status = 'absent' THEN 1 END) AS absent_count,
    COUNT(CASE WHEN da.status = 'leave' THEN 1 END) AS leave_count
FROM daily_attendance da
JOIN employees e ON da.employee_id = e.id
GROUP BY e.department, da.date;
