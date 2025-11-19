# SCP Supplier Web Portal

A production-ready Next.js web application for Supplier Owners, Managers, and Sales Representatives to manage their business on the SCP Platform. This application has been fully rewritten using the 361 LAB design system while maintaining full integration with the scp-backend Go API.

## Features

### Role-Based Dashboards
- **Owner Dashboard**: Revenue performance tracking, team overview, business metrics
- **Manager Dashboard**: Order approval performance, catalog management, order processing
- **Sales Dashboard**: Consumer management, communication center, complaint handling

### Core Functionality
- **Authentication & RBAC**: JWT-based authentication with role-based access control (Owner/Manager/Sales Rep)
- **Dashboard Analytics**: Role-specific dashboards with charts and key performance indicators
- **Catalog Management**: Create, edit, delete products with image upload support
- **Order Management**: View, accept, and reject orders with real-time status updates
- **Consumer Link Management**: Approve, reject, block consumer connection requests
- **Complaint Management**: Handle and resolve consumer complaints
- **User Management** (Owner Only): Create and manage team members
- **Team Management** (Owner Only): View and manage all team members across roles

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS + Stylus Modules (hybrid approach)
- **State Management**: Zustand + TanStack React Query
- **UI Components**: Custom components (361 LAB design system) + Radix UI primitives
- **Form Handling**: React Hook Form + Zod validation
- **API Client**: Axios with interceptors
- **Testing**: Vitest + React Testing Library
- **Fonts**: Geist Sans & Geist Mono

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Running SCP Platform API backend

### Installation

1. Install dependencies:

```bash
npm install
# or
yarn install
```

2. Set up environment variables:

Create a `.env.local` file:

```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080/api/v1
```

For production:
```env
NEXT_PUBLIC_API_BASE_URL=https://api.scp-platform.com/api/v1
```

3. Run the development server:

```bash
npm run dev
# or
yarn dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
scp-supplier-web/
├── app/                          # Next.js App Router pages
│   ├── (auth)/                   # Authentication routes
│   │   └── login/               # Login page
│   ├── owner/                    # Owner routes
│   │   ├── dashboard/           # Owner dashboard
│   │   ├── team/                # Team management
│   │   ├── settings/            # Account settings
│   │   └── layout.tsx           # Owner layout
│   ├── manager/                  # Manager routes
│   │   ├── dashboard/           # Manager dashboard
│   │   ├── catalog/             # Product catalog
│   │   │   └── create/          # Create product
│   │   ├── orders/              # Order management
│   │   │   └── [orderId]/       # Order details
│   │   ├── complaints/          # Complaint handling
│   │   │   └── [id]/            # Complaint details
│   │   └── layout.tsx           # Manager layout
│   ├── sales/                    # Sales rep routes
│   │   ├── dashboard/           # Sales dashboard
│   │   ├── consumers/           # Consumer management
│   │   └── messages/            # Communication center
│   ├── layout.tsx                # Root layout
│   ├── providers.tsx             # React Query provider
│   └── globals.css               # Global styles
├── components/                    # React components
│   ├── auth/                     # Authentication components
│   ├── dashboard/                # Dashboard components
│   ├── layout/                   # Layout components
│   │   ├── dashboard-shell.tsx  # Main dashboard shell
│   │   └── dashboard-shell.module.styl
│   ├── navigation/               # Navigation components
│   │   ├── role-sidebar-nav.tsx
│   │   ├── sidebar-link.tsx
│   │   ├── user-avatar.tsx
│   │   └── sidebar-toggle.tsx
│   ├── providers/                # Context providers
│   └── ui/                       # Reusable UI components
│       ├── button.tsx
│       ├── input.tsx
│       ├── label.tsx
│       ├── card.tsx
│       ├── page-header.tsx
│       └── section-card.tsx
├── constants/                     # Constants and configurations
│   └── navigation.ts             # Navigation configuration
├── lib/                           # Core utilities
│   ├── api/                      # API client functions
│   │   ├── auth.ts              # Authentication API
│   │   ├── client.ts            # Axios client setup
│   │   ├── dashboard.ts         # Dashboard API
│   │   ├── products.ts          # Products API
│   │   ├── orders.ts            # Orders API
│   │   ├── users.ts             # Users API
│   │   ├── consumers.ts         # Consumer links API
│   │   └── complaints.ts        # Complaints API
│   ├── store/                    # Zustand stores
│   │   └── auth-store.ts        # Authentication store
│   ├── types/                    # TypeScript types
│   │   └── index.ts             # Type definitions
│   └── utils/                    # Utility functions
│       ├── transform.ts         # Data transformation utilities
│       └── cn.ts                # Class name utilities
├── __tests__/                     # Test files
│   ├── setup.ts                  # Test setup and mocks
│   ├── api/                      # API tests
│   ├── store/                    # Store tests
│   └── utils/                    # Utility tests
├── middleware.ts                  # Next.js middleware for auth & routing
├── next.config.js                 # Next.js configuration (with Stylus support)
├── tailwind.config.ts             # Tailwind CSS configuration
├── vitest.config.ts               # Vitest configuration
└── package.json
```

## Role-Based Access Control

### Owner
- **Dashboard**: Revenue performance tracking with charts
- **Team Management**: Create and manage Manager and Sales Rep accounts
- **Full Access**: All features available to other roles
- **Account Settings**: Business account configuration

### Manager
- **Dashboard**: Order approval performance tracking
- **Catalog Management**: Full product catalog CRUD operations
- **Order Management**: Accept/reject orders, view order details
- **Complaint Handling**: Resolve consumer complaints
- **Settings**: Manager account settings

### Sales Representative
- **Dashboard**: Sales performance metrics
- **Consumer Management**: View and manage consumer connections
- **Communication Center**: Real-time messaging with consumers
- **Complaint Handling**: Escalate and track complaints

## API Integration

The app connects to the scp-backend Go API at `/api/v1`. All API calls are handled through:

- **Client-side**: `lib/api/client.ts` - Browser-based API client with localStorage token management
- **Server-side**: `lib/api/client.ts` - Server-side API client for SSR

### Authentication Flow

1. User submits credentials on login page
2. Frontend calls `/api/v1/auth/login` with role parameter
3. Backend returns JWT access_token and user data
4. Token stored in localStorage for client-side requests
5. Token automatically attached to all API requests via Axios interceptors
6. Middleware validates token and enforces role-based routing

### Backend Response Format

All API responses follow the standard format:

**Success Response:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error message"
  }
}
```

The frontend automatically transforms snake_case backend responses to camelCase for convenience while maintaining backward compatibility.

## Styling Architecture

The application uses a hybrid styling approach:

- **Tailwind CSS**: Utility classes for rapid development and consistent spacing
- **Stylus Modules**: Component-specific styles with CSS Modules for complex, unique designs
- **361 LAB Design System**: Consistent color palette, typography, and component patterns

### Stylus Modules

Stylus files use `.module.styl` extension and are imported as CSS Modules:

```typescript
import styles from './component.module.styl'
<div className={styles.container}>
```

## Testing

The application includes comprehensive test coverage using Vitest and React Testing Library.

### Running Tests

```bash
# Run tests in watch mode
npm test

# Run tests once
npm run test:run

# Run tests with coverage
npm run test:coverage
```

### Test Structure

- **API Tests**: Full coverage of all API client functions
  - Authentication (login, logout, getCurrentUser)
  - Products (CRUD operations, bulk update)
  - Orders (fetch, accept, reject)
  - Dashboard stats
  - Users management
  - Consumer links
  - Complaints

- **Store Tests**: Zustand store behavior testing
  - Authentication state management
  - User loading and permission checking

- **Utility Tests**: Helper function validation
  - Data transformation utilities
  - Type conversion (snake_case ↔ camelCase)

### Test Coverage

All tests verify:
- Correct API endpoint calls
- Proper request/response handling
- Error handling and edge cases
- Token management and authentication
- Data transformation and type safety

## Building for Production

```bash
# Build the application
npm run build

# Start production server
npm start
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_BASE_URL` | API base URL | `http://localhost:8080/api/v1` |

For different environments:

**Development:**
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080/api/v1
```

**Staging:**
```env
NEXT_PUBLIC_API_BASE_URL=https://staging-api.scp-platform.com/api/v1
```

**Production:**
```env
NEXT_PUBLIC_API_BASE_URL=https://api.scp-platform.com/api/v1
```

## Development Commands

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - TypeScript type checking
- `npm test` - Run tests in watch mode
- `npm run test:run` - Run tests once
- `npm run test:coverage` - Generate test coverage report

## Features Details

### Dashboard Pages

**Owner Dashboard:**
- Monthly revenue chart with trend visualization
- Key metrics: Total orders, link requests, low stock alerts
- Download reports functionality

**Manager Dashboard:**
- Order approval rate chart (FY performance)
- Service metrics: Inventory fill rate, SLA compliance
- Orders requiring action table
- Recent activity overview

### Catalog Management

- Product listing with status filters (On Sale, To Be On Sale, Draft)
- Category-based organization
- Image upload support (drag & drop)
- Product creation form with validation
- Bulk operations support
- Stock level management
- Pricing and discount management

### Order Management

- Filter orders by status (Pending, Accepted, Completed, Rejected, Cancelled)
- Search by order ID
- Order detail views with item breakdown
- Accept/Reject actions with confirmation
- Real-time stock updates on acceptance
- Delivery window information

### Consumer Links

- View all consumer link requests
- Approve/Reject pending requests
- Block/unlink existing consumer connections
- Consumer information display
- Link request history

### Complaint Management

- Filter by status (New, Resolved, In Progress, Escalated)
- View complaint details
- Resolve with resolution notes
- Priority-based organization
- Related order information

### User Management (Owner Only)

- Create Manager and Sales Rep accounts
- View all team members
- User status management (active, suspended, inactive)
- Role assignment
- Delete users (except self)

## Architecture Notes

### Authentication

- JWT tokens stored in localStorage (client-side)
- Automatic token refresh handling
- Role-based route protection via middleware
- Automatic redirect on 401 errors

### Data Flow

1. User action triggers API call
2. Axios interceptor adds JWT token to request
3. Backend validates token and processes request
4. Response transformed from snake_case to camelCase
5. React Query manages caching and refetching
6. UI updates with new data

### Type Safety

- Full TypeScript coverage
- Backend response types defined in `lib/types/index.ts`
- API client functions are fully typed
- Component props validated with TypeScript

### Error Handling

- Centralized error handling in API client
- Toast notifications for user feedback
- Graceful degradation on API failures
- Error boundaries for React components

## Migration from 361 LAB

This application was fully rewritten using code from the 361 LAB folder while maintaining compatibility with the existing scp-backend Go API. Key changes:

- Replaced cookie-based sessions with JWT tokens
- Updated all API calls to use backend endpoints
- Migrated all UI components and styling
- Maintained role-based routing structure
- Preserved design system and user experience

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## License

Copyright © 2024 SCP Platform
