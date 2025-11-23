# SCP Mobile Apps

Flutter mobile applications for the SCP Platform.

## Apps

- **Consumer App** (`scp-consumer-app`) - For restaurants and hotels
- **Supplier Sales App** (`scp-supplier-sales-app`) - For supplier sales representatives

## Setup

### Prerequisites
- Flutter SDK 3.24.0+
- Dart SDK

### Installation

1. **Install shared package dependencies**:
   ```bash
   cd scp-mobile-shared
   flutter pub get
   ```

2. **Setup Consumer App**:
   ```bash
   cd scp-consumer-app
   flutter pub get
   flutter gen-l10n
   ```

3. **Setup Supplier Sales App**:
   ```bash
   cd scp-supplier-sales-app
   flutter pub get
   flutter gen-l10n
   ```

## Running

### Development
```bash
# Consumer App
cd scp-consumer-app
flutter run --dart-define=ENV=development

# Supplier Sales App
cd scp-supplier-sales-app
flutter run --dart-define=ENV=development
```

### iOS
```bash
flutter run -d ios
```

### Android
```bash
flutter run -d android
```

## Building for Production

### Android
```bash
# APK
flutter build apk --release --dart-define=ENV=production

# App Bundle
flutter build appbundle --release --dart-define=ENV=production
```

### iOS
```bash
flutter build ios --release --dart-define=ENV=production
# Then archive in Xcode
```

## Key Features

### Consumer App
- Supplier discovery and search
- Link request management
- Product catalog browsing
- Shopping cart and ordering
- Order tracking
- Real-time chat
- Multi-language (EN, RU, KK)

### Supplier Sales App
- Dashboard with statistics
- Chat with canned replies
- Complaint management
- Order viewing
- Real-time notifications
- Multi-language (EN, RU, KK)

## Shared Package

Both apps use `scp-mobile-shared` for:
- Data models
- API services
- UI widgets
- Configuration

## Configuration

### API URL
- **Development**: Auto-configured to `http://localhost:3000/api/v1`
- **Custom**: `flutter run --dart-define=API_BASE_URL=http://your-api-url/api/v1`

### Environment
- `ENV=development` - Development mode (default)
- `ENV=production` - Production mode

## Testing

```bash
# Shared package
cd scp-mobile-shared && flutter test

# Consumer app
cd scp-consumer-app && flutter test

# Supplier app
cd scp-supplier-sales-app && flutter test
```

---

For more details, see the main [README](../README.md).
