# SCP Platform

B2B platform connecting institutional consumers (restaurants, hotels) with suppliers. Complete ecosystem with backend API, mobile applications, and web portal.

## Project Structure

```
scp-platform/
├── scp-backend/              # Go backend API service
├── scp-mobile-shared/        # Shared Dart package
├── scp-consumer-app/         # Consumer Flutter mobile app
├── scp-supplier-sales-app/   # Supplier sales Flutter mobile app
└── scp-supplier-web/         # Supplier web portal (Next.js)
```

## Quick Start

### Prerequisites
- **Backend**: Go 1.21+, PostgreSQL 15+
- **Mobile Apps**: Flutter SDK 3.24.0+
- **Web Portal**: Node.js 18+

### Backend
```bash
cd scp-backend
go mod download
cp env.example .env  # Edit with your database credentials
createdb scp_platform
# Run migrations
for migration in migrations/*.sql; do
  psql -U postgres -d scp_platform -f "$migration"
done
go run cmd/api/main.go
```

**Or with Docker:**
```bash
cd scp-backend
docker-compose up -d
```

Backend runs on `http://localhost:3000`

### Mobile Apps
```bash
# Install shared package
cd scp-mobile-shared && flutter pub get

# Consumer App
cd ../scp-consumer-app
flutter pub get && flutter gen-l10n
flutter run --dart-define=ENV=development

# Supplier Sales App
cd ../scp-supplier-sales-app
flutter pub get && flutter gen-l10n
flutter run --dart-define=ENV=development
```

### Web Portal
```bash
cd scp-supplier-web
npm install
echo "NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api/v1" > .env.local
npm run dev
```

## Architecture

### Backend
- **Layered Architecture**: Handlers → Services → Repositories → Database
- **RESTful API** with WebSocket for real-time features
- **JWT Authentication** with role-based access control
- **PostgreSQL** with migrations

### Mobile Apps
- **BLoC Pattern**: Cubits for state management
- **Shared Package**: Common models, services, widgets
- **Multi-language**: EN, RU, KK

### Web Portal
- **Next.js App Router** with TypeScript
- **Zustand** for state management
- **Role-based access**: Owner, Manager, Sales Rep

## Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Backend API | Go, Gin, PostgreSQL | REST API & WebSocket service |
| Consumer App | Flutter | Mobile app for restaurants/hotels |
| Supplier Sales App | Flutter | Mobile app for sales representatives |
| Web Portal | Next.js, TypeScript | Web app for owners/managers |
| Shared Package | Dart | Shared code for mobile apps |

## API Configuration

All frontend apps connect to backend API:

- **Development**: `http://localhost:3000/api/v1`
- **Flutter**: Auto-configured (use `ENV=development`)
- **Next.js**: Set `NEXT_PUBLIC_API_BASE_URL` in `.env.local`

## CI/CD Pipeline

This project uses GitHub Actions for automated testing and building:

### Automated Testing

The CI/CD pipeline automatically runs tests for all components:

- **Go Backend**: Unit tests with coverage reporting
- **Flutter Consumer App**: Unit tests and code analysis
- **Flutter Supplier App**: Unit tests and code analysis
- **Next.js Web Portal**: Linting and build verification

### Android APK Builds

On every push to `main` branch or manual trigger:

- Builds release APKs for both Flutter apps
- Uses matrix strategy for parallel builds
- Uploads APKs as workflow artifacts (stored for 30 days)
- Provides direct download links in workflow summary

### Download APKs

1. Go to the [Actions tab](https://github.com/YOUR_USERNAME/YOUR_REPO/actions) in your repository
2. Select the latest workflow run
3. Scroll to the "Artifacts" section
4. Download the APK files:
   - `consumer-app-apk` - Consumer App APK
   - `supplier-app-apk` - Supplier Sales App APK

### Manual Workflow Trigger

You can manually trigger the workflow:
1. Go to Actions → CI/CD Pipeline
2. Click "Run workflow"
3. Select branch and click "Run workflow"

### Release Builds

For production releases, use the `Release Build` workflow:
1. Go to Actions → Release Build
2. Click "Run workflow"
3. Enter version number (e.g., `1.0.0`)
4. Optionally create git tags

### Environment Variables

The following secrets can be configured in GitHub repository settings:

- `ANDROID_KEYSTORE_PASSWORD` - Password for Android keystore (optional, uses debug keys if not set)
- `ANDROID_KEY_PASSWORD` - Password for Android signing key (optional, uses debug keys if not set)

> **Note:** For production builds, configure proper Android signing keys in repository secrets.

## Documentation

- [Backend README](scp-backend/README.md) - Backend setup and API
- [Mobile Apps README](scp-consumer-app/README.md) - Flutter apps setup
- [Web Portal README](scp-supplier-web/README.md) - Next.js setup
