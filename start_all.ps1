Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   Starting Payroll Staff Attendance System (Both)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$root = $PSScriptRoot

Write-Host "`n[1/2] Starting Spring Boot Backend (Port 8080)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$root\backend'; .\mvnw.cmd spring-boot:run"

Write-Host "[2/2] Starting Flutter App (Chrome / Port 7357)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$root\flutter_application_1'; flutter run -d chrome --web-port=7357"

Write-Host "`n✓ Both services launched in separate windows!" -ForegroundColor Green
Write-Host "- Backend: http://localhost:8080"
Write-Host "- Flutter: http://localhost:7357"
