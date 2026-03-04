# CI/CD Setup Guide for Leave Management Flutter App

This guide explains how to use the automated CI/CD pipeline for your Flutter leave management application.

## Overview

The CI/CD setup includes:
- ✅ Environment-based configuration (development vs production)
- ✅ Automated building and testing on Git push
- ✅ Automatic deployment to your server
- ✅ Easy environment switching for local development

## Environment Configuration

### Current Setup:
- **Development**: `http://localhost:8000/api`
- **Production**: `http://31.97.71.5/leave-api/api`

### Switching Environments

#### On Windows:
```bash
# Switch to development (localhost)
switch_env.bat dev

# Switch to production (live server)
switch_env.bat prod

# Check current environment
switch_env.bat status
```

#### On Mac/Linux:
```bash
# Make script executable (only first time)
chmod +x switch_env.sh

# Switch to development (localhost)
./switch_env.sh dev

# Switch to production (live server)
./switch_env.sh prod

# Check current environment
./switch_env.sh status
```

## GitHub Secrets Setup

For the CI/CD pipeline to work, you need to add these secrets to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Add these secrets:

| Secret Name | Value |
|-------------|--------|
| `HOST` | `31.97.71.5` |
| `USERNAME` | `root` |
| `PASSWORD` | `P@@@ss0rd1245` |

### Steps to add secrets:
1. Click **"New repository secret"**
2. Name: `HOST`, Value: `31.97.71.5`
3. Click **"Add secret"**
4. Repeat for `USERNAME` and `PASSWORD`

## How CI/CD Works

### Automatic Triggers:
- ✅ **Push to main/master branch** → Builds and deploys to production
- ✅ **Pull requests** → Runs tests and build validation only

### Pipeline Steps:
1. **Code Checkout** - Downloads your latest code
2. **Flutter Setup** - Installs Flutter SDK
3. **Dependencies** - Downloads all packages (`flutter pub get`)
4. **Testing** - Runs all tests (`flutter test`)
5. **Code Analysis** - Checks code quality (`flutter analyze`)
6. **Production Build** - Builds web app for production
7. **Deployment** - Uploads files to your server at `/var/www/html/leave_management/leave_management_flutter/`
8. **Permissions** - Sets proper file permissions on server

## Local Development Workflow

1. **Start development**:
   ```bash
   switch_env.bat dev  # Switch to localhost
   flutter run -d chrome  # Run on local browser
   ```

2. **Test your changes**:
   ```bash
   flutter test  # Run tests
   flutter analyze  # Check code quality
   ```

3. **Build for production**:
   ```bash
   switch_env.bat prod  # Switch to production
   flutter build web --release --base-href /leave-app/
   ```

4. **Push to deploy**:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin main  # This triggers automatic deployment
   ```

## Server Deployment Path

Your Flutter web app will be deployed to:
```
/var/www/html/leave_management/leave_management_flutter/
```

Make sure your web server (Apache/Nginx) is configured to serve files from this directory.

## Manual Deployment (if needed)

If you need to deploy manually:

1. Build the app:
   ```bash
   switch_env.bat prod
   flutter build web --release --base-href /leave-app/
   ```

2. Upload `build/web/` contents to your server at:
   ```
   /var/www/html/leave_management/leave_management_flutter/
   ```

## Troubleshooting

### Common Issues:

1. **Build fails**: Check that all tests pass locally first
2. **Deployment fails**: Verify GitHub secrets are set correctly
3. **App doesn't load**: Check server permissions and web server configuration

### Environment Issues:
- If API calls fail, check current environment with `switch_env.bat status`
- Ensure your Laravel API is running on the correct URL

### Pipeline Monitoring:
- Check GitHub Actions tab in your repository for deployment status
- Look at the logs for any error details

## File Structure

```
.github/workflows/deploy.yml    # CI/CD pipeline configuration
lib/core/config/environment.dart # Environment configuration
lib/core/constants/app_constants.dart # Updated to use environment config
switch_env.bat                  # Windows environment switcher
switch_env.sh                   # Mac/Linux environment switcher
```

## Next Steps

1. ✅ Add GitHub secrets (HOST, USERNAME, PASSWORD)
2. ✅ Test local development with `switch_env.bat dev`
3. ✅ Push changes to trigger first automatic deployment
4. ✅ Verify deployment on your server

Your CI/CD pipeline is now ready! 🚀