# SCP - Consumer App

A production-ready Flutter mobile application for Restaurants and Hotels (B2B Consumers) to discover suppliers, place orders, and manage business relationships.

## Project Overview

**SCP (Supplier Consumer Platform)** is a B2B platform connecting institutional consumers (restaurants, hotels) with suppliers. This is the Consumer app that allows businesses to:

- Discover and link with suppliers
- Browse product catalogs
- Place and track orders
- Communicate with suppliers through chat
- Manage business relationships

## Features

### ✅ Authentication
- Secure login with email/password
- Role-based access control (Consumer)
- Token-based authentication
- Auto-refresh tokens

### ✅ Supplier Management
- **Supplier Discovery**: Search and find suppliers
- **Link Requests**: Send and manage connection requests
- **Link Status**: Track pending, accepted, rejected, and blocked requests
- View supplier profiles with ratings and reviews

### ✅ Catalog & Ordering
- **Product Catalog**: Browse products from linked suppliers only
- **Product Details**: View images, prices, stock levels, minimum order quantities
- **Shopping Cart**: Add/remove items, update quantities
- **Order Placement**: Multi-step checkout process
- **Order Tracking**: Real-time order status updates
- **Order History**: View past and current orders

### ✅ Communication
- **Integrated Chat**: Real-time messaging with supplier sales reps
- **File Sharing**: Send images and documents
- **Complaint Threads**: Link complaints to specific orders
- **Message Notifications**: Push notifications for new messages

### ✅ Notifications
- Order status updates
- Message notifications
- Link request outcomes
- Push notifications support

### ✅ Localization
- English (en)
- Russian (ru)
- Kazakh (kk)

## Technical Architecture

### State Management
- **flutter_bloc** with Cubits for reactive state management
- Separation of concerns with dedicated cubits per feature

### Navigation
- Bottom navigation bar (Home, Orders, Chat, Profile)
- Intuitive routing and navigation

### Networking
- **Dio** for HTTP requests
- REST API integration
- JWT token-based authentication
- Interceptors for request/response handling

### Local Storage
- **shared_preferences** for app settings
- **flutter_secure_storage** for sensitive data (tokens)

### UI/UX
- Material Design 3
- WCAG 2.1 AA compliant
- Minimum touch targets 48x48
- Professional B2B design
- Smooth animations and transitions

## Project Structure

```
lib/
├── config/              # App configuration and themes
├── cubits/              # State management (BLoC)
│   ├── auth_cubit.dart
│   ├── cart_cubit.dart
│   ├── chat_cubit.dart
│   ├── notification_cubit.dart
│   ├── order_cubit.dart
│   ├── product_cubit.dart
│   └── supplier_cubit.dart
├── generated/           # Generated files (l10n)
├── l10n/                # Localization files (.arb)
├── models/              # Data models
│   ├── message_model.dart
│   ├── notification_model.dart
│   ├── order_item_model.dart
│   ├── order_model.dart
│   ├── product_model.dart
│   ├── supplier_model.dart
│   └── user_model.dart
├── screens/             # UI screens
│   ├── auth/
│   ├── chat/
│   ├── home/
│   ├── order/
│   ├── profile/
│   └── supplier/
├── services/            # API services
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── http_service.dart
│   ├── notification_service.dart
│   ├── order_service.dart
│   ├── product_service.dart
│   ├── storage_service.dart
│   └── supplier_service.dart
├── utils/               # Utilities and helpers
│   └── app_validators.dart
├── widgets/             # Reusable widgets
│   ├── empty_state_widget.dart
│   ├── error_widget.dart
│   ├── loading_indicator.dart
│   ├── product_card.dart
│   └── supplier_card.dart
└── main.dart            # App entry point
```

## Setup & Installation

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile builds)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

## Configuration

### API Endpoint
Update the base URL in `lib/config/app_config.dart`:
```dart
static const String baseUrl = 'https://api.scp-platform.com/api/v1';
```

### Localization
Localization files are in `lib/l10n/`:
- `app_en.arb` - English
- `app_ru.arb` - Russian
- `app_kk.arb` - Kazakh

Add new translations to these files and run `flutter gen-l10n`.

## API Endpoints

The app expects the following REST API endpoints:

### Authentication
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Refresh token

### Suppliers
- `GET /suppliers/discover` - Discover suppliers
- `GET /suppliers/:id` - Get supplier details
- `POST /suppliers/:id/link-request` - Send link request
- `GET /consumer/link-requests` - Get link requests
- `GET /consumer/linked-suppliers` - Get linked suppliers

### Products
- `GET /consumer/products` - Get products from linked suppliers
- `GET /consumer/products/:id` - Get product details
- `GET /consumer/products/categories` - Get categories

### Orders
- `POST /consumer/orders` - Place order
- `GET /consumer/orders` - Get order history
- `GET /consumer/orders/:id` - Get order details
- `GET /consumer/orders/current` - Get current orders
- `POST /consumer/orders/:id/cancel` - Cancel order

### Chat
- `GET /consumer/conversations` - Get conversations
- `GET /consumer/conversations/:id/messages` - Get messages
- `POST /consumer/conversations/:id/messages` - Send message
- `POST /consumer/conversations` - Start conversation

### Notifications
- `GET /consumer/notifications` - Get notifications
- `POST /consumer/notifications/:id/read` - Mark as read

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Dependencies

Key dependencies:
- `flutter_bloc` ^8.1.3 - State management
- `dio` ^5.3.2 - HTTP client
- `shared_preferences` ^2.5.3 - Local storage
- `flutter_secure_storage` ^9.2.4 - Secure storage
- `cached_network_image` ^3.4.1 - Image caching
- `image_picker` ^1.2.0 - Image selection
- `flutter_local_notifications` ^16.3.3 - Push notifications
- `socket_io_client` ^2.0.3 - Real-time communication

See `pubspec.yaml` for the complete list.

## Accessibility

The app follows WCAG 2.1 AA guidelines:
- Minimum touch target size: 48x48 pixels
- High contrast text
- Screen reader support
- Semantic labels

## Contributing

This is a production-ready app. When making changes:

1. Follow the existing code structure
2. Add comments for complex logic
3. Ensure all tests pass
4. Maintain code quality standards
5. Update documentation as needed

## License

Copyright © 2024 SCP Platform

## Support

For issues or questions, please contact the development team.

---

**Note:** This is the Consumer app. The Supplier app is a separate project.
