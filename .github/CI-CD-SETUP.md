# CI/CD Setup Guide

This guide will help you set up the complete CI/CD pipeline for the SCP Platform.

## Quick Start

1. **Update Badge URLs** in `README.md` (replace `YOUR_USERNAME` and `YOUR_REPO`)
2. **Push to GitHub** - The workflow will run automatically
3. **Download APKs** from the Actions tab after builds complete

## What's Included

### ✅ Automated Testing
- Go backend unit tests with coverage
- Flutter consumer app tests
- Flutter supplier app tests  
- Next.js web portal linting and build verification

### ✅ Android APK Builds
- Release APKs for both Flutter apps
- Parallel builds using matrix strategy
- 30-day artifact storage
- Direct download links in workflow summary

### ✅ Workflow Triggers
- Push to `main` branch
- Pull requests to `main`
- Manual trigger via GitHub UI

## Setup Steps

### 1. Update Repository Information

Edit `README.md` and replace:
- `YOUR_USERNAME` → Your GitHub username
- `YOUR_REPO` → Your repository name

Example:
```markdown
[![CI/CD Pipeline](https://github.com/johndoe/scp-platform/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/johndoe/scp-platform/actions/workflows/ci-cd.yml)
```

### 2. Configure Android Signing (Optional)

For production builds, you'll want to use proper signing keys:

#### Option A: Use the Setup Script

```bash
./scripts/setup-github-secrets.sh
```

This will:
- Generate a keystore file
- Provide instructions for adding GitHub secrets
- Guide you through the setup

#### Option B: Manual Setup

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore android-release.jks \
     -storepass YOUR_PASSWORD \
     -keypass YOUR_PASSWORD \
     -alias release-key \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Add GitHub Secrets:
   - Go to: **Settings → Secrets and variables → Actions**
   - Add:
     - `ANDROID_KEYSTORE_PASSWORD`: Your keystore password
     - `ANDROID_KEY_PASSWORD`: Your key password

**Note:** If secrets are not configured, the workflow uses debug keys (testing only).

### 3. Configure Code Coverage (Optional)

For code coverage reporting:

1. Sign up at [codecov.io](https://codecov.io)
2. Add your repository
3. Get your upload token
4. Add `CODECOV_TOKEN` secret to GitHub

## Using the Workflows

### CI/CD Pipeline (Automatic)

Runs automatically on:
- Every push to `main`
- Pull requests to `main`
- Manual trigger

**To manually trigger:**
1. Go to **Actions** tab
2. Select **CI/CD Pipeline**
3. Click **Run workflow**
4. Select branch and click **Run workflow**

### Release Build (Manual)

For production releases:

1. Go to **Actions** tab
2. Select **Release Build**
3. Click **Run workflow**
4. Enter version number (e.g., `1.0.0`)
5. Choose whether to create git tags

## Downloading APKs

After a workflow completes:

1. Go to the **Actions** tab
2. Click on the latest workflow run
3. Scroll to the **Artifacts** section
4. Download:
   - `consumer-app-apk` - Consumer App APK
   - `supplier-app-apk` - Supplier Sales App APK

## Workflow Features

### Matrix Strategy
Both Flutter apps build in parallel for faster execution.

### Dependency Caching
- Go modules cached
- Flutter packages cached
- Node.js dependencies cached

### Artifact Management
- APKs stored for 30 days (CI/CD) or 90 days (Release)
- Direct download links in workflow summary
- Easy access from Actions tab

## Troubleshooting

### Build Fails

1. Check workflow logs for specific errors
2. Verify Flutter version matches project requirements
3. Ensure all dependencies are correctly specified
4. Check Android SDK configuration

### APK Not Generated

1. Verify build step completed successfully
2. Check APK path in workflow logs
3. Ensure Flutter build completed without errors
4. Check artifact upload step

### Signing Issues

1. Verify keystore secrets are correctly set
2. Check passwords match your keystore
3. Ensure keystore alias is correct
4. For production, use proper signing keys

## Workflow Files

- `.github/workflows/ci-cd.yml` - Main CI/CD pipeline
- `.github/workflows/release.yml` - Release builds
- `.github/workflows/README.md` - Detailed workflow documentation

## Environment Variables

The workflows use these environment variables (set in workflow files):

- `FLUTTER_VERSION`: `3.24.0`
- `GO_VERSION`: `1.21`
- `NODE_VERSION`: `18`

To change versions, edit the workflow files.

## Support

For issues:
1. Check workflow logs
2. Review `.github/workflows/README.md`
3. Open an issue in the repository


