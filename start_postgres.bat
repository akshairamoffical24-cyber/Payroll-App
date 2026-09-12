@echo off
echo ========================================================
echo   Starting PostgreSQL Service (postgresql-x64-18)
echo ========================================================

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Starting PostgreSQL Windows Service...
    net start postgresql-x64-18
    goto check_status
) else (
    echo Requesting Administrator privileges to start the service...
    powershell -Command "Start-Process cmd -ArgumentList '/c net start postgresql-x64-18 && timeout /t 3' -Verb RunAs -Wait"
)

:check_status
echo.
sc query postgresql-x64-18 | findstr "STATE"
echo.
echo If the service is RUNNING, you can now run your Spring Boot app in IntelliJ.
pause
