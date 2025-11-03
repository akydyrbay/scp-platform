# SCP Platform Backend

A comprehensive Go backend service for the Supplier Consumer Platform (SCP), providing REST API and WebSocket support for Flutter mobile apps and Next.js web portal.

## Features

- **Authentication & Authorization**: JWT-based authentication with role-based access control (consumer, owner, manager, sales_rep)
- **Product Management**: CRUD operations for products with inventory management
- **Order Management**: Order creation, acceptance, rejection with stock validation
- **Consumer-Supplier Linking**: Link request, approval, rejection workflow
- **Complaint System**: Complaint logging, escalation, and resolution
- **Real-time Chat**: WebSocket-based messaging between consumers and suppliers
- **Dashboard Analytics**: Statistics and metrics for suppliers
- **File Uploads**: Image and document upload support
- **Notifications**: In-app notification system

## Tech Stack

- **Language**: Go 1.21+
- **Web Framework**: Gin
- **Database**: PostgreSQL
- **Cache/Sessions**: Redis (optional)
- **Authentication**: JWT (golang-jwt/jwt/v5)
- **WebSocket**: Gorilla WebSocket
- **Database ORM**: SQLX

## Project Structure

```
scp-backend/
├── cmd/
│   └── api/
│       └── main.go                 # Application entry point
├── internal/
│   ├── api/
│   │   ├── handlers/               # HTTP handlers
│   │   ├── middleware/             # Middleware functions
│   │   ├── websocket/              # WebSocket hub
│   │   └── routes.go               # Route definitions
│   ├── models/                     # Data models
│   ├── services/                   # Business logic
│   ├── repository/                 # Data access layer
│   └── config/                     # Configuration
├── pkg/
│   ├── jwt/                        # JWT utilities
│   └── password/                   # Password hashing
├── migrations/                     # Database migrations
├── docker-compose.yml              # Docker Compose setup
├── Dockerfile                      # Docker image
├── go.mod                          # Go modules
└── README.md                       # This file
```

## Prerequisites

- Go 1.21 or higher
- PostgreSQL 15+
- Redis (optional, for sessions)
- Docker & Docker Compose (optional)

## Installation

### Local Development

1. **Clone the repository**:
   ```bash
   cd scp-backend
   ```

2. **Install dependencies**:
   ```bash
   go mod download
   ```

3. **Set up environment variables**:
   Create a `.env` file (copy from `.env.example`):
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=postgres
   DB_NAME=scp_platform
   JWT_SECRET=your-secret-key-change-in-production
   ```

4. **Set up the database**:
   ```bash
   # Create database
   createdb scp_platform
   
   # Run migrations
   psql -U postgres -d scp_platform -f migrations/001_create_suppliers.sql
   psql -U postgres -d scp_platform -f migrations/002_create_users.sql
   # ... run all migration files in order
   ```

5. **Run the application**:
   ```bash
   go run cmd/api/main.go
   ```

### Docker Setup

1. **Build and run with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

   This will start:
   - API server on port 3000
   - PostgreSQL on port 5432
   - Redis on port 6379

2. **Run migrations**:
   Migrations should run automatically via the docker-entrypoint-initdb.d volume. If not, you can run them manually:
   ```bash
   docker exec -i scp-backend-postgres-1 psql -U postgres -d scp_platform < migrations/001_create_suppliers.sql
   ```

## API Endpoints

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
- `POST /api/v1/supplier/complaints` - Create complaint
- `POST /api/v1/supplier/complaints/:id/escalate` - Escalate complaint
- `GET /api/v1/supplier/dashboard/stats` - Get dashboard stats

### WebSocket
- `WS /api/v1/ws` - WebSocket connection for real-time updates

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `ENV` | Environment (development/production) | `development` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `DB_NAME` | Database name | `scp_platform` |
| `JWT_SECRET` | JWT signing secret | (required) |
| `JWT_ACCESS_EXPIRY` | Access token expiry (minutes) | `15` |
| `JWT_REFRESH_EXPIRY` | Refresh token expiry (days) | `7` |
| `REDIS_HOST` | Redis host | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | `http://localhost:3000,...` |

## Database Schema

The application uses PostgreSQL with the following main tables:
- `suppliers` - Supplier information
- `users` - User accounts (consumers, owners, managers, sales reps)
- `products` - Product catalog
- `orders` - Customer orders
- `order_items` - Order line items
- `consumer_links` - Consumer-supplier relationships
- `conversations` - Chat conversations
- `messages` - Chat messages
- `complaints` - Complaint tracking
- `notifications` - User notifications
- `canned_replies` - Canned reply templates

See `migrations/` directory for complete schema definitions.

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <access_token>
```

**Token Structure**:
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "role": "consumer|owner|manager|sales_rep",
  "supplier_id": "uuid (if applicable)",
  "exp": 1234567890
}
```

## Role-Based Access Control

| Role | Access |
|------|--------|
| `consumer` | Consumer endpoints, own orders, conversations |
| `owner` | Full supplier management, user management |
| `manager` | Supplier management (no user management) |
| `sales_rep` | Conversations, complaints, order viewing |

## Testing

### Run tests:
```bash
go test ./...
```

### Integration testing:
Set up test database and run:
```bash
go test -tags=integration ./...
```

## Development

### Code Structure
- **Handlers**: HTTP request/response handling
- **Services**: Business logic layer
- **Repository**: Database access layer
- **Models**: Data structures
- **Middleware**: Request processing middleware

### Adding New Endpoints

1. Create handler in `internal/api/handlers/`
2. Add service logic in `internal/services/` if needed
3. Add repository methods in `internal/repository/` if needed
4. Register route in `internal/api/routes.go`

## Production Deployment

1. **Set environment variables** in production environment
2. **Use strong JWT_SECRET** (generate with `openssl rand -hex 32`)
3. **Enable SSL mode** for database (`DB_SSLMODE=require`)
4. **Configure CORS** origins properly
5. **Set up reverse proxy** (nginx) for SSL termination
6. **Enable connection pooling** in database
7. **Set up monitoring** and logging
8. **Use Docker** for containerized deployment

## Health Check

The service provides a health check endpoint:
```
GET /health
```

Returns: `{"status": "ok"}`

## License

Copyright © 2024 SCP Platform

## Support

For issues and questions, refer to the main project documentation or contact the development team.

