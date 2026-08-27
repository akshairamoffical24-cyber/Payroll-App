@echo off
echo ========================================================
echo   Starting Payroll Staff Attendance System
echo ========================================================

echo [1/2] Launching Spring Boot Backend (Port 8080)...
start "Backend - Spring Boot" cmd /k "cd /d "%~dp0backend" && mvnw.cmd spring-boot:run"

echo [2/2] Launching Flutter Application...
start "Frontend - Flutter Web" cmd /k "cd /d "%~dp0flutter_application_1" && flutter run -d chrome --web-port=7357"

echo ========================================================
echo Both services are launching in separate windows!
echo - Backend API: http://localhost:8080
echo - Flutter App: http://localhost:7357
echo ========================================================
