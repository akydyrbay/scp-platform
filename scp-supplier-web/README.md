# SCP Supplier Web Portal

A Next.js web application for supplier owners and managers to manage their business operations, including product catalog, orders, team members, and consumer links.

## Technology Stack

- **Framework**: Next.js 16+ (App Router)
- **Language**: TypeScript
- **UI Library**: React 19+
- **State Management**: Zustand
- **Form Handling**: React Hook Form + Zod
- **HTTP Client**: Axios
- **Notifications**: React Hot Toast
- **Styling**: Tailwind CSS
- **Icons**: Lucide React

## Features

### 🔐 Authentication
- JWT-based authentication with automatic token refresh
- Role-based access control (Owner, Manager, Sales Rep)
- Secure token storage in localStorage
- Automatic redirect on authentication errors

### 📊 Dashboard
- Real-time statistics and metrics
- Order overview and pending requests
- Low stock alerts
- Recent activity feed

### 📦 Product Catalog Management
- **Product Creation**: Create products with images, pricing, inventory details, and category assignment
- **Product Editing**: Edit products (available for "On Sale", "To Be On Sale", and "Draft" status)
- **Product Deletion**: Delete products with confirmation dialog
- **Category Management**:
  - Preset categories: Fresh Fruit, Premium Meat, Dairy, Bakery, Seasonal, Organic
  - Category filtering with "All" option to show all products
  - Category stored in description field as `[Category] Description` format
  - Automatic category extraction and display
- **Product Status Management**:
  - **Draft**: `stock_level = 0` (default for new products)
  - **To Be On Sale**: `stock_level > 0` and `discount = null/0`
  - **On Sale**: `stock_level > 0` and `discount > 0`
- **Product Actions**:
  - **Publish**: Sets product to "On Sale" (adds discount > 0 and stock > 0)
  - **Discontinue**: Changes "On Sale" to "To Be On Sale" (removes discount)
  - **Edit Listing**: Available for all statuses (On Sale, To Be On Sale, Draft)
  - **Delete**: Remove product permanently with confirmation
- **Filtering**:
  - Status filters: On Sale, To Be On Sale, Draft
  - Category filters: All, Fresh Fruit, Premium Meat, Dairy, Bakery, Seasonal, Organic
  - Combined filtering (status + category)
- **Image Upload**: Drag & drop or file selection, automatic upload to server
- **Inventory Tracking**: Stock levels, minimum order quantities, pricing

### 🛒 Order Management
- View all orders with pagination
- Accept or reject orders
- Filter by status (Pending, Accepted, Rejected)
- Order details and item breakdown

### 👥 Team Management (Owner Only)
- Create and manage Manager and Sales Representative accounts
- User creation with role assignment
- Delete team members
- View team directory

### 🔗 Consumer Link Management
- View consumer link requests
- Approve or reject link requests
- Block consumers
- Filter by status (pending, approved, rejected, blocked)

### 📋 Complaint Handling (Manager)
- View all complaints with consumer information
- Filter by status (open, escalated, resolved)
- View complaint details including:
  - Issue summary and description
  - Consumer contact information
  - Associated order (if any)
  - Conversation history
  - Priority level (low, medium, high, urgent)
- Resolve complaints with manager response
- Access conversation messages as complaint history
- Navigate to chat with consumer

### ⚙️ Account Settings
- View personal information
- Update profile details
- Sign out functionality

## Project Structure

```
scp-supplier-web/
├── app/
│   ├── (auth)/              # Authentication pages
│   │   ├── login/           # Login page
│   │   └── signup/          # Owner registration page
│   ├── owner/               # Owner workspace
│   │   ├── dashboard/       # Owner dashboard
│   │   ├── team/            # Team management
│   │   └── settings/        # Account settings
│   ├── manager/             # Manager workspace
│   │   ├── dashboard/       # Manager dashboard
│   │   ├── catalog/         # Product catalog
│   │   │   ├── create/      # Create product
│   │   │   └── [id]/edit/   # Edit product
│   │   ├── orders/          # Order management
│   │   ├── complaints/      # Complaint handling
│   │   │   └── [id]/        # Complaint detail page
│   │   ├── links/           # Consumer links
│   │   └── settings/        # Account settings
│   └── layout.tsx           # Root layout
├── components/
│   ├── ui/                  # Reusable UI components
│   ├── auth/                # Authentication components
│   ├── navigation/          # Navigation components
│   └── providers/           # Context providers
├── lib/
│   ├── api/                 # API client functions
│   │   ├── client.ts        # Axios client with interceptors
│   │   ├── auth.ts          # Authentication API
│   │   ├── products.ts      # Product API
│   │   ├── orders.ts        # Order API
│   │   ├── users.ts         # User management API
│   │   ├── consumer-links.ts # Consumer links API
│   │   ├── complaints.ts    # Complaints API
│   │   ├── dashboard.ts     # Dashboard API
│   │   └── upload.ts        # File upload API
│   ├── store/               # Zustand stores
│   │   └── auth-store.ts    # Authentication state
│   ├── auth-guard.tsx       # Route protection component
│   └── types/               # TypeScript types
├── middleware.ts            # Next.js middleware
└── package.json             # Dependencies
```

## Installation

### Prerequisites

- Node.js 18+ and npm/yarn
- Backend API running (see `scp-backend/README.md`)

### Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set up environment variables**:
   Create `.env.local`:
   ```env
   NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api/v1
   ```

3. **Run development server**:
   ```bash
   npm run dev
   ```

   The app will run on `http://localhost:3001` (port 3001 to avoid conflict with backend)

4. **Build for production**:
   ```bash
   npm run build
   npm start
   ```

## Product Status System

Products have three statuses determined by `stock_level` and `discount`:

| Status | Condition | Can Edit? | Actions Available |
|--------|-----------|-----------|-------------------|
| **Draft** | `stock_level = 0` | ✅ Yes | Edit Listing, Publish, Delete |
| **To Be On Sale** | `stock_level > 0` and `discount = null/0` | ✅ Yes | Edit Listing, Publish, Delete |
| **On Sale** | `stock_level > 0` and `discount > 0` | ✅ Yes | Edit Listing, Discontinue, Delete |

### Product Actions

1. **Publish** (Draft or To Be On Sale → On Sale):
   - Sets `stock_level > 0` (defaults to 1 if was 0)
   - Sets `discount > 0` (defaults to 10% if was 0/null)
   - Product becomes "On Sale"

2. **Discontinue** (On Sale → To Be On Sale):
   - Removes discount (`discount = 0`)
   - Keeps `stock_level` unchanged
   - Product becomes "To Be On Sale"

3. **Edit Listing** (All Statuses):
   - Allows editing all product fields
   - Can update pricing, inventory, description, images, category
   - Category changes saved as `[Category] Description` format
   - Available for all product statuses

4. **Delete** (All Statuses):
   - Permanently removes product from database
   - Requires confirmation dialog
   - Refreshes product list after deletion

## Data Storage

Products are stored in the PostgreSQL database in the `products` table:

**Database**: PostgreSQL (`scp_platform`)  
**Table**: `products`  
**Schema**: See `scp-backend/migrations/003_create_products.sql`

**Product Fields**:
- `id` (UUID) - Primary key
- `name` (VARCHAR) - Product name
- `description` (TEXT) - Product description (may contain category in `[Category] Description` format)
- `image_url` (TEXT) - Product image URL
- `unit` (VARCHAR) - Unit of measurement
- `price` (DECIMAL) - Base price
- `discount` (DECIMAL) - Discount percentage (0-100, nullable)
- `stock_level` (INTEGER) - Available stock quantity
- `min_order_quantity` (INTEGER) - Minimum order quantity
- `supplier_id` (UUID) - Foreign key to suppliers table
- `created_at` (TIMESTAMP) - Creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Category Storage**:
- Categories are stored in the `description` field using the format: `[Category Name] Product description`
- Supported categories: Fresh Fruit, Premium Meat, Dairy, Bakery, Seasonal, Organic
- Categories are automatically extracted and displayed in the product listing
- When no category is assigned, products are displayed as "Uncategorized"

## API Integration

The web portal connects to the Go backend API (`scp-backend`). All API calls are handled through:

- **Base URL**: `NEXT_PUBLIC_API_BASE_URL` (default: `http://localhost:3000/api/v1`)
- **Authentication**: JWT tokens stored in localStorage
- **Client**: Axios with automatic token injection and refresh

### Key API Endpoints

- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/auth/refresh` - Refresh access token
- `GET /api/v1/supplier/products` - List products (paginated)
- `GET /api/v1/supplier/products/:id` - Get single product (verifies ownership, enhanced error logging)
- `POST /api/v1/supplier/products` - Create product
- `PUT /api/v1/supplier/products/:id` - Update product (verifies ownership)
- `DELETE /api/v1/supplier/products/:id` - Delete product (verifies ownership, returns detailed error messages)
- `GET /api/v1/supplier/orders` - List orders
- `POST /api/v1/supplier/orders/:id/accept` - Accept order
- `POST /api/v1/supplier/orders/:id/reject` - Reject order
- `GET /api/v1/supplier/consumer-links` - List consumer links
- `POST /api/v1/supplier/consumer-links/:id/approve` - Approve link
- `POST /api/v1/supplier/consumer-links/:id/reject` - Reject link
- `GET /api/v1/supplier/complaints` - List complaints (with consumer information)
- `GET /api/v1/supplier/complaints/:id` - Get single complaint with details
- `POST /api/v1/supplier/complaints/:id/resolve` - Resolve complaint
- `POST /api/v1/supplier/complaints/:id/escalate` - Escalate complaint
- `GET /api/v1/supplier/conversations/:id/messages` - Get conversation messages (for history)
- `POST /api/v1/upload` - Upload file/image

## Role-Based Access Control

### Owner Role
- Full access to all features
- Can create/manage team members (Managers and Sales Reps)
- Can manage all products, orders, and consumer links

### Manager Role
- Can manage products, orders, and consumer links
- Can handle complaints (view, resolve, escalate)
- Cannot manage team members
- Can view dashboard statistics

### Sales Rep Role
- Limited access (sales-specific features)
- Chat and conversation management
- Complaint handling

## Recent Updates

### Product Management Enhancements
- ✅ Product creation with image upload support
- ✅ Product editing (restricted to Draft and To Be On Sale products)
- ✅ Status-based action buttons (Publish/Discontinue/Edit)
- ✅ Automatic status determination based on stock and discount
- ✅ Image placeholder when no image uploaded
- ✅ Optimized product listing with status filters

### Catalog Features
- ✅ Status filtering (On Sale, To Be On Sale, Draft)
- ✅ Category filtering (All, Fresh Fruit, Premium Meat, Dairy, Bakery, Seasonal, Organic)
- ✅ Combined filtering (status + category)
- ✅ Product actions based on status (Publish, Discontinue, Edit, Delete)
- ✅ Edit listing page with full product editing (all statuses)
- ✅ Product deletion with confirmation
- ✅ Category management (assign/update categories)
- ✅ Image upload and management
- ✅ Real-time status updates

### Consumer Link Management
- ✅ Consumer link approval/rejection page
- ✅ Link status filtering
- ✅ Block consumer functionality
- ✅ Navigation menu integration

### Authentication & Authorization
- ✅ JWT token management with automatic refresh
- ✅ Route protection with AuthGuard component
- ✅ Role-based access control
- ✅ Automatic redirect on authentication errors
- ✅ Owner sign-up page for company registration

### Team Management (Owner Only)
- ✅ Create Manager and Sales Rep accounts
- ✅ User deletion
- ✅ Team directory view
- ✅ Form validation and error handling

### Complaint Handling (Manager)
- ✅ View complaints list with consumer information
- ✅ Filter complaints by status (open, escalated, resolved)
- ✅ View complaint details with full context
- ✅ Display consumer contact information
- ✅ Show conversation history from messages
- ✅ Resolve complaints with manager response
- ✅ Priority level display (low, medium, high, urgent)
- ✅ Integration with conversation system

## Development

### Code Style
- Use TypeScript for type safety
- Follow Next.js App Router conventions
- Use functional components with hooks
- Implement proper error handling and loading states
- Use React Hook Form for form management
- Validate forms with Zod schemas

### Adding New Features

1. Create API functions in `lib/api/`
2. Add UI components in `components/`
3. Create pages in `app/` directory
4. Update navigation in layout files
5. Add route protection if needed

## Production Deployment

1. Set `NEXT_PUBLIC_API_BASE_URL` in production environment
2. Build the application: `npm run build`
3. Start production server: `npm start`
4. Configure reverse proxy (nginx) for SSL
5. Set up domain and DNS

## License

Copyright © 2024 SCP Platform

---

**Last Updated**: December 2024

## Recent Features

### Product Management
- ✅ Product deletion with confirmation dialog
- ✅ Category filtering with 6 preset categories + All option
- ✅ Category assignment and management
- ✅ Edit products in all statuses (including "On Sale")
- ✅ Enhanced error handling and logging for product operations

