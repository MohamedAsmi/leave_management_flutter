@echo off
setlocal

set "ENVIRONMENT_FILE=lib\core\config\environment.dart"

if "%1"=="dev" goto :set_development
if "%1"=="development" goto :set_development
if "%1"=="prod" goto :set_production
if "%1"=="production" goto :set_production
if "%1"=="status" goto :show_current
if "%1"=="current" goto :show_current
goto :usage

:set_development
echo Setting environment to DEVELOPMENT...
powershell -Command "(Get-Content '%ENVIRONMENT_FILE%') -replace 'Environment\.production', 'Environment.development' | Set-Content '%ENVIRONMENT_FILE%'"
echo Environment set to development (localhost:8000)
goto :end

:set_production
echo Setting environment to PRODUCTION...
powershell -Command "(Get-Content '%ENVIRONMENT_FILE%') -replace 'Environment\.development', 'Environment.production' | Set-Content '%ENVIRONMENT_FILE%'"
echo Environment set to production (31.97.71.5)
goto :end

:show_current
findstr /c:"Environment.development" "%ENVIRONMENT_FILE%" >nul
if %errorlevel%==0 (
    echo Current environment: DEVELOPMENT (localhost:8000)
) else (
    echo Current environment: PRODUCTION (31.97.71.5)
)
goto :end

:usage
echo Usage: %0 {dev^|prod^|status}
echo   dev/development  - Switch to development environment (localhost:8000)
echo   prod/production  - Switch to production environment (31.97.71.5)
echo   status/current   - Show current environment
goto :end

:end