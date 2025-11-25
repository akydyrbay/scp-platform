# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated CI/CD.

## Workflows

### 1. CI/CD Pipeline (`ci-cd.yml`)

Main workflow that runs on every push to `main`, pull requests, and manual triggers.

**Features:**
- ✅ Tests all components (Go backend, Flutter apps, Next.js web)
- ✅ Builds Android APKs for both Flutter apps
- ✅ Parallel builds using matrix strategy
- ✅ Caches dependencies for faster builds
- ✅ Uploads APKs as artifacts (30-day retention)
- ✅ Generates workflow summary with download links

**Triggers:**
- Push to `main` branch
- Pull requests to `main` branch
- Manual trigger via `workflow_dispatch`

### 2. Release Build (`release.yml`)

Production release workflow for creating versioned releases.

**Features:**
- Builds release APKs with version numbers
- Creates git tags for releases
- Stores artifacts for 90 days
- Manual trigger only

**Usage:**
1. Go to Actions → Release Build
2. Click "Run workflow"
3. Enter version number (e.g., `1.0.0`)
4. Choose whether to create git tags

## Setup Instructions

### 1. Update Badge URLs

In the main `README.md`, replace the placeholder badge URLs:
- Replace `YOUR_USERNAME` with your GitHub username
- Replace `YOUR_REPO` with your repository name

Example:
```markdown
[![CI/CD Pipeline](https://github.com/yourusername/scp-platform/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/yourusername/scp-platform/actions/workflows/ci-cd.yml)
```

### 2. Configure Android Signing (Optional)

For production builds, configure Android signing keys:

1. Generate a keystore file:
   ```bash
   keytool -genkey -v -keystore android-keystore.jks \
     -storepass YOUR_KEYSTORE_PASSWORD \
     -keypass YOUR_KEY_PASSWORD \
     -alias release-key \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Add secrets to GitHub repository:
   - Go to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `ANDROID_KEYSTORE_PASSWORD`: Your keystore password
     - `ANDROID_KEY_PASSWORD`: Your key password
     - `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file (optional, for custom keystore)

3. Update workflow to use custom keystore (if needed):
   - Modify the "Create keystore for signing" step in `ci-cd.yml`
   - Or use the keystore from secrets if you've uploaded it

**Note:** If secrets are not configured, the workflow will use debug keys (suitable for testing only).

### 3. Code Coverage (Optional)

For code coverage reporting, configure Codecov:

1. Sign up at [codecov.io](https://codecov.io)
2. Add your repository
3. Get your upload token
4. Add `CODECOV_TOKEN` secret to GitHub repository

The workflow will automatically upload coverage reports if the token is configured.

## Workflow Structure

```
┌─────────────────┐
│  Push/PR/Manual │
└────────┬────────┘
         │
         ├─→ Test Backend
         ├─→ Test Consumer App
         ├─→ Test Supplier App
         ├─→ Test Web Portal
         │
         └─→ Build Android APKs (if push/manual)
              ├─→ Consumer App APK
              └─→ Supplier App APK
```

## Artifact Access

After a workflow run completes:

1. Go to the workflow run page
2. Scroll to the "Artifacts" section
3. Download the APK files:
   - `consumer-app-apk`: Consumer App APK
   - `supplier-app-apk`: Supplier Sales App APK

Artifacts are available for:
- **CI/CD Pipeline**: 30 days
- **Release Build**: 90 days

## Troubleshooting

### Build Fails

1. Check workflow logs for specific errors
2. Verify all dependencies are correctly specified
3. Ensure Flutter version matches project requirements
4. Check if Android SDK is properly configured

### APK Not Generated

1. Verify the build step completed successfully
2. Check if APK path is correct in workflow
3. Ensure Flutter build completed without errors
4. Check artifact upload step for errors

### Signing Issues

1. Verify keystore secrets are correctly set
2. Check keystore password and key password match
3. Ensure keystore alias is correct
4. For production, use proper signing keys (not debug keys)

## Customization

### Change Flutter Version

Update `FLUTTER_VERSION` in workflow files:
```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # Change to desired version
```

### Change Node.js Version

Update `NODE_VERSION` in workflow files:
```yaml
env:
  NODE_VERSION: '18'  # Change to desired version
```

### Change Go Version

Update `GO_VERSION` in workflow files:
```yaml
env:
  GO_VERSION: '1.21'  # Change to desired version
```

### Modify Build Targets

To build for different Android architectures, update the build command:
```yaml
flutter build apk --release \
  --target-platform android-arm64,android-arm,android-x64
```

## Support

For issues or questions:
1. Check workflow logs
2. Review this documentation
3. Open an issue in the repository

