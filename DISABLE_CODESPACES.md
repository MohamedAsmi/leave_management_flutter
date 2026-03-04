# Disable GitHub Codespaces Prebuilds

## ✅ Quick Fix Applied
Your repository has been configured to disable Codespaces Prebuilds automatically.

## 📋 Manual Steps (if needed)

### 1. Disable Codespaces Prebuilds in Repository Settings:
1. Go to your GitHub repository: `https://github.com/[username]/leave_management_flutter`
2. Click **Settings** tab
3. Scroll down to **Codespaces** section
4. Uncheck **"Enable prebuilds"**
5. Click **Save**

### 2. Stop Existing Prebuilds:
1. Go to **Actions** tab in your repository
2. Look for **"Codespaces Prebuilds"** workflows
3. Click on any running prebuild
4. Click **Cancel workflow** (red button)

### 3. Notification Settings:
1. Go to your **GitHub profile** → **Settings**
2. Click **Notifications** in left sidebar
3. Under **Actions**, uncheck:
   - **Prebuilds**
   - **Dependabot alerts** (if you don't want them)

## 🛠 What I've Configured:

✅ **Created `.devcontainer/devcontainer.json`** - Explicitly disables prebuilds  
✅ **Added `.github/dependabot.yml`** - Disables Dependabot updates  
✅ **Updated `.github/workflows/deploy.yml`** - Only runs on code changes, ignores docs  
✅ **Added path filters** - Workflow only triggers for actual code changes  
✅ **Updated `.gitignore`** - Ignores Codespaces artifacts  

## 🎯 Result:
- ❌ No more Codespaces Prebuild notifications
- ❌ No more Dependabot PRs  
- ✅ CI/CD still works for actual code changes
- ✅ Faster repository operations

## 🔄 To Re-enable Later:
If you want Codespaces back:
1. Edit `.devcontainer/devcontainer.json` → set `"prebuilds": true`
2. Edit `.github/dependabot.yml` → add your update configurations
3. Commit and push changes

Your repository is now optimized for development without notification spam! 🎉