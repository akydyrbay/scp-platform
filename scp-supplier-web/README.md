# SCP Supplier Web Portal

Next.js web application for supplier owners and managers to manage business operations.

## Tech Stack

- **Next.js** 16+ (App Router)
- **TypeScript**
- **React** 19+
- **Zustand** (state management)
- **Tailwind CSS** (styling)

## Setup

### Prerequisites
- Node.js 18+
- Backend API running (see `scp-backend/README.md`)

### Installation

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
   
   App runs on `http://localhost:3001` (port 3001 to avoid conflict with backend)

## Features

- **Dashboard** - Statistics and metrics
- **Product Catalog** - Create, edit, delete products with inventory management
- **Order Management** - View, accept, reject orders
- **Consumer Links** - Approve/reject consumer link requests
- **Team Management** (Owner only) - Create/manage team members
- **Complaint Handling** (Manager) - View and resolve complaints

## Project Structure

```
scp-supplier-web/
├── app/              # Next.js App Router pages
├── components/       # React components
├── lib/
│   ├── api/         # API client functions
│   └── store/       # Zustand stores
└── middleware.ts    # Next.js middleware for auth
```

## Key API Endpoints

- `POST /api/v1/auth/login` - Login
- `GET /api/v1/supplier/products` - List products
- `POST /api/v1/supplier/products` - Create product
- `PUT /api/v1/supplier/products/:id` - Update product
- `DELETE /api/v1/supplier/products/:id` - Delete product
- `GET /api/v1/supplier/orders` - List orders
- `POST /api/v1/supplier/orders/:id/accept` - Accept order
- `GET /api/v1/supplier/consumer-links` - List consumer links
- `POST /api/v1/supplier/consumer-links/:id/approve` - Approve link

## Role-Based Access

| Role | Access |
|------|--------|
| **Owner** | Full access + team management |
| **Manager** | Product, order, link management + complaints |
| **Sales Rep** | Limited access (chat, complaints) |

## Building for Production

```bash
npm run build
npm start
```

## Production Deployment

1. Set `NEXT_PUBLIC_API_BASE_URL` in production environment
2. Build: `npm run build`
3. Start: `npm start`
4. Configure reverse proxy (nginx) for SSL
5. Set up domain and DNS

---

For more details, see the main [README](../README.md).
