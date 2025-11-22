# SCP Platform - Complete B2B Solution

A comprehensive, production-ready B2B platform connecting institutional consumers (restaurants, hotels) with suppliers. This repository contains a complete ecosystem with backend API, mobile applications, and web portal.

## 📁 Project Structure

```
scp-platform/
├── scp-backend/              # Go backend API service
│   ├── cmd/api/             # Application entry point
│   ├── internal/            # Internal packages
│   │   ├── api/             # HTTP handlers, routes, middleware
│   │   ├── models/          # Data models
│   │   ├── services/        # Business logic
│   │   ├── repository/      # Database access layer
│   │   └── config/          # Configuration
│   ├── migrations/          # Database migrations
│   ├── pkg/                 # Public packages (JWT, password)
│   └── docker-compose.yml   # Docker setup
│
├── scp-mobile-shared/        # Shared Dart package
│   ├── lib/
│   │   ├── models/          # Shared data models
│   │   ├── services/        # Shared API services
│   │   ├── widgets/         # Reusable UI widgets
│   │   ├── config/          # App configuration & themes
│   │   └── utils/           # Utility functions
│   └── pubspec.yaml
│
├── scp-consumer-app/        # Consumer Flutter mobile app
│   ├── lib/
│   │   ├── main.dart        # Consumer app entry
│   │   ├── cubits/          # Consumer-specific state
│   │   ├── screens/         # Consumer screens
│   │   └── l10n/            # Localization files
│   ├── android/             # Android configuration
│   ├── ios/                 # iOS configuration
│   └── pubspec.yaml
│
├── scp-supplier-sales-app/  # Supplier sales Flutter mobile app
│   ├── lib/
│   │   ├── main.dart        # Supplier app entry
│   │   ├── cubits/          # Supplier-specific state
│   │   ├── screens/         # Supplier screens
│   │   └── l10n/            # Localization files
│   ├── android/             # Android configuration
│   ├── ios/                 # iOS configuration
│   └── pubspec.yaml
│
├── scp-supplier-web/        # Supplier web portal (Next.js)
│   ├── app/                 # Next.js App Router pages
│   ├── components/          # React components
│   ├── lib/                 # Core utilities
│   │   ├── api/             # API client functions
│   │   ├── store/           # Zustand stores
│   │   ├── types/           # TypeScript types
│   │   └── utils/           # Utility functions
│   └── middleware.ts        # Next.js middleware for auth
│
└── README.md                # This file
```

## 🎯 Project Overview

The SCP Platform is a complete B2B solution consisting of:

### 1️⃣ Backend API (`scp-backend`)
**Technology**: Go 1.21+, Gin, PostgreSQL, Redis  
**Purpose**: RESTful API and WebSocket service for all frontend applications

**Features:**
- JWT-based authentication with role-based access control
- Product management with inventory tracking
- Order management with stock validation
- Consumer-supplier linking workflow
- Real-time chat via WebSocket
- Complaint system with escalation
- Dashboard analytics
- File upload support
- User management for suppliers

**API Base URL**: `https://api.scp-platform.com/api/v1` (production)

### 2️⃣ Consumer Mobile App (`scp-consumer-app`)
**Technology**: Flutter, Dart  
**Purpose**: Mobile application for restaurants and hotels

**Features:**
- Supplier discovery and search
- Link request management
- Product catalog browsing
- Shopping cart and ordering
- Order tracking and history
- Integrated chat with suppliers
- Multi-language support (EN, RU, KK)

**Theme**: Professional blue (#1E3A8A)

### 3️⃣ Supplier Sales Mobile App (`scp-supplier-sales-app`)
**Technology**: Flutter, Dart  
**Purpose**: Mobile application for supplier sales representatives

**Features:**
- Dashboard with live statistics
- Enhanced chat with canned replies
- Complaint logging and management
- One-tap escalation to manager
- Read-only order viewing
- Real-time notifications
- Multi-language support (EN, RU, KK)

**Theme**: Dynamic purple (#7C3AED)

### 4️⃣ Supplier Web Portal (`scp-supplier-web`)
**Technology**: Next.js 14+, TypeScript, React  
**Purpose**: Web application for supplier owners and managers

**Features:**
- Dashboard with key metrics
- User management (Owner: create/delete Manager and Sales Rep accounts)
- Catalog & inventory management
- Consumer link management (approve/reject/block)
- Order management (accept/reject)
- Incident management (view and resolve complaints)

**Access**: Desktop-optimized, responsive design

### 5️⃣ Shared Package (`scp-mobile-shared`)
**Purpose**: Shared Dart package for both mobile applications

**Contains:**
- Data models (User, Order, Product, Message, Supplier, etc.)
- API service layer (HTTP, Auth, Storage, and specialized services)
- Reusable UI widgets (LoadingIndicator, ErrorDisplay, ProductCard, etc.)
- App configuration (themes, environment management)
- Utility functions and validators

## 🚀 Quick Start

### Prerequisites

- **Backend**: Go 1.21+, PostgreSQL 15+, Redis (optional)
- **Mobile Apps**: Flutter SDK 3.24.0+, Dart SDK
- **Web Portal**: Node.js 18+, npm/yarn
- **Development**: Docker & Docker Compose (optional)

### 1. Backend Setup

```bash
cd scp-backend

# Install dependencies
go mod download

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials

# Create database
createdb scp_platform

# Run migrations
for migration in migrations/*.sql; do
  psql -U postgres -d scp_platform -f "$migration"
done

# Run the server
go run cmd/api/main.go
```

**Or with Docker:**
```bash
cd scp-backend
docker-compose up -d
```

Backend runs on `http://localhost:3000`

### 2. Mobile Apps Setup

**Install shared package dependencies:**
```bash
cd scp-mobile-shared
flutter pub get
```

**Consumer App:**
```bash
cd scp-consumer-app
flutter pub get
flutter gen-l10n
flutter run --dart-define=ENV=development
```

**Supplier Sales App:**
```bash
cd scp-supplier-sales-app
flutter pub get
flutter gen-l10n
flutter run --dart-define=ENV=development
```

### 3. Web Portal Setup

```bash
cd scp-supplier-web

# Install dependencies
npm install

# Set up environment variables
echo "NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api/v1" > .env.local

# Run development server
npm run dev
```

Web portal runs on `http://localhost:3000` (or next available port)

## 🔗 Integration & Configuration

### API Base URLs

All frontend applications connect to the backend API. Configure as follows:

| Environment | Backend URL | Flutter Config | Next.js Config |
|-------------|-------------|----------------|----------------|
| Development | `http://localhost:3000/api/v1` | Auto (default) | `.env.local` |
| Staging | `https://staging-api.scp-platform.com/api/v1` | `ENV=staging` | Environment variable |
| Production | `https://api.scp-platform.com/api/v1` | `ENV=production` | Environment variable |

### Flutter Apps Configuration

**Default (Development):**
```bash
flutter run --dart-define=ENV=development
# Uses http://localhost:3000/api/v1 automatically
```

**Custom API URL:**
```bash
flutter run --dart-define=ENV=development \
  --dart-define=API_BASE_URL=http://your-api-url/api/v1
```

### Next.js Web Portal Configuration

**Development:**
```bash
# Create .env.local
echo "NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api/v1" > .env.local
npm run dev
```

**Production:**
Set `NEXT_PUBLIC_API_BASE_URL` in your deployment environment.

### Authentication Flow

All applications use JWT-based authentication:

1. **Login**: `POST /api/v1/auth/login`
   - Returns: `{access_token, refresh_token, user}`
2. **Token Usage**: Include in `Authorization: Bearer <token>` header
3. **Refresh**: `POST /api/v1/auth/refresh` when access token expires
4. **Auto-handling**: Frontend apps automatically inject tokens and handle 401 errors

## 📦 Building for Production

### Backend

```bash
cd scp-backend

# Build binary
go build -o main ./cmd/api

# Or use Docker
docker build -t scp-backend .
docker run -p 3000:3000 scp-backend
```

### Consumer Mobile App

**Android:**
```bash
cd scp-consumer-app
flutter build apk --release --dart-define=ENV=production
flutter build appbundle --release --dart-define=ENV=production
```

**iOS:**
```bash
cd scp-consumer-app
flutter build ios --release --dart-define=ENV=production
# Then archive in Xcode
```

### Supplier Sales Mobile App

**Android:**
```bash
cd scp-supplier-sales-app
flutter build apk --release --dart-define=ENV=production
flutter build appbundle --release --dart-define=ENV=production
```

**iOS:**
```bash
cd scp-supplier-sales-app
flutter build ios --release --dart-define=ENV=production
# Then archive in Xcode
```

### Web Portal

```bash
cd scp-supplier-web
npm run build
npm start
```

## 🔐 Production Deployment Checklist

### Backend
- [ ] Set strong `JWT_SECRET` (generate with `openssl rand -hex 32`)
- [ ] Configure database with SSL (`DB_SSLMODE=require`)
- [ ] Set up reverse proxy (nginx) for SSL termination
- [ ] Configure CORS origins properly
- [ ] Enable connection pooling
- [ ] Set up monitoring and logging
- [ ] Configure file storage (S3 for production)

### Mobile Apps
- [ ] Create and configure Android keystores (see [Android Signing Setup](ANDROID_SIGNING_SETUP.md))
- [ ] Set up `key.properties` files (never commit to git!)
- [ ] Configure iOS bundle identifiers in Xcode
- [ ] Set up Apple Developer account and provisioning profiles
- [ ] Test release builds on physical devices
- [ ] Configure App Store Connect / Play Console
- [ ] Add custom app icons and splash screens
- [ ] Test ProGuard/R8 builds thoroughly

### Web Portal
- [ ] Set `NEXT_PUBLIC_API_BASE_URL` in production environment
- [ ] Configure domain and SSL certificate
- [ ] Set up CDN for static assets (optional)
- [ ] Enable production optimizations

## 🏗️ Architecture

### Backend Architecture
- **Layered Architecture**: Handlers → Services → Repositories → Database
- **Clean Separation**: Business logic in services, data access in repositories
- **RESTful Design**: REST API with WebSocket for real-time features
- **JWT Authentication**: Stateless authentication with role-based authorization
- **Database**: PostgreSQL with migrations for schema management

### Mobile Apps Architecture
- **BLoC Pattern**: Cubits for reactive state management
- **Shared Package**: Single source of truth for shared logic
- **Service Layer**: HTTP client with automatic token injection
- **Modular Design**: Clean separation between apps and shared code

### Web Portal Architecture
- **Next.js App Router**: Modern React framework with server-side rendering
- **State Management**: Zustand for global state, TanStack Query for server state
- **Type Safety**: Full TypeScript coverage
- **Component Library**: Radix UI + custom components (shadcn/ui style)

## 📋 API Endpoints Overview

### Authentication
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/auth/logout` - Logout

### Consumer Endpoints
- `GET /api/v1/consumer/suppliers` - List suppliers
- `POST /api/v1/suppliers/:id/link-request` - Request supplier link
- `GET /api/v1/consumer/supplier-links` - Get supplier links
- `GET /api/v1/consumer/products` - Get products from linked suppliers
- `POST /api/v1/consumer/orders` - Create order
- `GET /api/v1/consumer/orders` - Get orders
- `GET /api/v1/consumer/conversations` - Get conversations
- `POST /api/v1/consumer/conversations/:id/messages` - Send message

### Supplier Endpoints
- `GET /api/v1/supplier/products` - List products
- `POST /api/v1/supplier/products` - Create product
- `PUT /api/v1/supplier/products/:id` - Update product
- `DELETE /api/v1/supplier/products/:id` - Delete product
- `GET /api/v1/supplier/orders` - Get orders
- `POST /api/v1/supplier/orders/:id/accept` - Accept order
- `POST /api/v1/supplier/orders/:id/reject` - Reject order
- `GET /api/v1/supplier/consumer-links` - Get consumer links
- `POST /api/v1/supplier/consumer-links/:id/approve` - Approve link
- `GET /api/v1/supplier/dashboard/stats` - Get dashboard stats
- `POST /api/v1/supplier/users` - Create user (Owner/Manager only)
- `GET /api/v1/supplier/users` - List users (Owner/Manager only)

### WebSocket
- `WS /api/v1/ws` - WebSocket connection for real-time updates

For complete API documentation, see [Backend README](scp-backend/README.md) and [Backend Integration Guide](BACKEND_INTEGRATION_GUIDE.md).

## 🔒 Role-Based Access Control

| Role | Access Level | Applications |
|------|--------------|--------------|
| `consumer` | Consumer endpoints only | Consumer Mobile App |
| `owner` | Full supplier management + user management | Web Portal, Mobile (future) |
| `manager` | Supplier management (no user management) | Web Portal, Mobile (future) |
| `sales_rep` | Conversations, complaints, order viewing | Supplier Sales Mobile App |

## 🌍 Localization

Supported languages:
- **English** (en) - Default
- **Russian** (ru)
- **Kazakh** (kk)

Localization files are managed in each app's `l10n/` directory. Generate localization files:
```bash
flutter gen-l10n
```

## 🧪 Testing

### Backend
```bash
cd scp-backend
go test ./...
```

### Mobile Apps
```bash
# Shared package
cd scp-mobile-shared && flutter test

# Consumer app
cd scp-consumer-app && flutter test

# Supplier app
cd scp-supplier-sales-app && flutter test
```

### Web Portal
```bash
cd scp-supplier-web
npm run lint
npm run type-check
npm run build
```

### CI/CD

The project includes GitHub Actions workflows for:
- Automated testing (backend, mobile apps, web portal)
- Building release APKs for Android
- Type checking and linting
- Code coverage reporting

See [`.github/workflows/ci.yml`](.github/workflows/ci.yml) for details.

## 📚 Documentation

### Production Deployment
- **[Production Deployment Checklist](DEPLOYMENT_CHECKLIST.md)** ⭐ - Complete production deployment guide
- [Production Configuration Guide](scp-backend/PRODUCTION_CONFIG.md) - Backend production configuration
- [Monitoring and Logging Setup](MONITORING_SETUP.md) - Monitoring and logging configuration

### Setup Guides
- [Firebase Setup Guide](FIREBASE_SETUP.md) - Firebase integration instructions
- [Android Signing Setup](ANDROID_SIGNING_SETUP.md) - Android app signing guide
- [Testing Artifacts Guide](TESTING_ARTIFACTS.md) - How to test CI/CD artifacts

### Integration Documentation
- [Backend Integration Guide](BACKEND_INTEGRATION_GUIDE.md) - Complete backend API integration specifications
- [Backend README](scp-backend/README.md) - Backend service documentation
- [Backend Implementation Summary](scp-backend/IMPLEMENTATION_SUMMARY.md) - Backend implementation overview

### App-Specific Documentation
- [Consumer App README](scp-consumer-app/README.md) - Consumer app quick reference
- [Supplier Sales App README](scp-supplier-sales-app/README.md) - Supplier sales app quick reference
- [Supplier Web Portal README](scp-supplier-web/README.md) - Web portal documentation

## 📄 License

Copyright © 2024 SCP Platform

---

**Last Updated**: December 2024  
**Status**: Production Ready 🚀
