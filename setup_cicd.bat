@echo off
echo ================================
echo Flutter CI/CD Setup Script
echo ================================
echo.

echo Step 1: Checking Git status...
git status

echo.
echo Step 2: Adding all files...
git add .

echo.
echo Step 3: Committing CI/CD setup...
git commit -m "Add CI/CD pipeline with environment configuration

- Add environment-based configuration (dev/prod)
- Add GitHub Actions workflow for automated deployment
- Add environment switching scripts (Windows/Mac/Linux)
- Update app_constants.dart to use dynamic environment
- Add comprehensive CI/CD documentation

Deployment path: /var/www/html/leave_management/leave_management_flutter/
"

echo.
echo Step 4: Checking current environment...
call switch_env.bat status

echo.
echo ================================
echo Setup Complete! 
echo ================================
echo.
echo Next steps:
echo 1. Add GitHub secrets (HOST, USERNAME, PASSWORD)
echo    - Go to GitHub Settings ^> Secrets and variables ^> Actions
echo    - Add: HOST = 31.97.71.5
echo    - Add: USERNAME = root  
echo    - Add: PASSWORD = P@@@ss0rd1245
echo.
echo 2. Push to trigger first deployment:
echo    git push origin main
echo.
echo 3. For local development:
echo    switch_env.bat dev
echo.
echo 4. Check CI_CD_SETUP.md for detailed instructions
echo ================================