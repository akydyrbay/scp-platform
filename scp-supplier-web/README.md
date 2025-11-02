# SCP Supplier Web Portal

A production-ready Next.js web application for Supplier Owners and Managers to manage their business on the SCP Platform.

## Features

- **Authentication & RBAC**: Secure login with role-based access control (Owner/Manager)
- **Dashboard**: Overview with key metrics and recent activity
- **User Management** (Owner Only): Create, view, and remove Manager and Sales Representative accounts
- **Catalog & Inventory**: Create, edit, delete products with bulk update capabilities
- **Consumer Link Management**: View, approve, deny, block, and unlink consumer connections
- **Order Management**: View, accept, and reject bulk orders with real-time stock reduction
- **Incident Management** (Manager+): View and resolve complaints escalated by Sales Representatives

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: Zustand + TanStack Query
- **UI Components**: Radix UI + Custom components (shadcn/ui style)
- **Form Handling**: React Hook Form + Zod validation
- **API Client**: Axios

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Access to SCP Platform API

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
├── app/                    # Next.js App Router pages
│   ├── dashboard/         # Dashboard page
│   ├── users/             # User management (Owner only)
│   ├── catalog/           # Product catalog & inventory
│   ├── consumers/         # Consumer link management
│   ├── orders/            # Order management
│   ├── incidents/         # Incident/complaint management
│   └── login/             # Authentication page
├── components/            # React components
│   ├── ui/                # Reusable UI components
│   └── layout/            # Layout components (sidebar, etc.)
├── lib/                   # Core utilities
│   ├── api/               # API client functions
│   ├── store/             # Zustand stores
│   ├── types/             # TypeScript types
│   └── utils/             # Utility functions
└── middleware.ts           # Next.js middleware for auth
```

## Role-Based Access Control

### Owner
- Full access to all features
- User management (create/delete Manager and Sales Rep accounts)
- Account deletion capabilities

### Manager
- Access to all features except:
  - User management
  - Account deletion
- Can manage incidents/complaints

## API Integration

The app connects to the same REST API as the mobile apps. All API calls are handled through:
- Client-side: `lib/api/client.ts` (browser)
- Server-side: `lib/api/client.ts` (Next.js server)

Authentication tokens are stored in localStorage (client-side) and cookies (server-side).

## Building for Production

```bash
npm run build
npm start
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEXT_PUBLIC_API_BASE_URL` | API base URL | `https://api.scp-platform.com/api/v1` |

## Development

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - TypeScript type checking

## Features Details

### Dashboard
- Key metrics: Total orders, pending orders, pending link requests, low stock items
- Recent orders display
- Low stock products alert

### User Management (Owner Only)
- Create Manager and Sales Representative accounts
- View all users
- Delete users (except self)

### Catalog & Inventory
- Create products with: name, description, image, unit, price, discount, stock level, min order quantity
- Edit existing products
- Delete products
- Bulk update stock and prices (API ready)

### Consumer Links
- View pending link requests
- Approve/Reject requests
- Block/Unlink existing consumers

### Orders
- View all orders
- Accept/Reject pending orders
- Real-time stock reduction on acceptance
- Order details view with items

### Incidents (Manager+)
- View escalated complaints
- Resolve incidents with resolution notes
- Filter by status and priority

## Notes

- The app is optimized for desktop use with responsive design
- Mobile use is secondary but functional
- All forms include validation
- Error handling with toast notifications
- Loading states for all async operations
- Type-safe throughout with TypeScript

## License

Copyright © 2024 SCP Platform

