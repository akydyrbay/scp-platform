# SCP Backend

Go backend API service providing REST API and WebSocket support for the SCP Platform.

## Tech Stack

- **Go** 1.21+
- **Gin** web framework
- **PostgreSQL** database
- **JWT** authentication

## Setup

### Prerequisites
- Go 1.21+
- PostgreSQL 15+

### Installation

1. **Install dependencies**:
   ```bash
   go mod download
   ```

2. **Set up environment variables**:
   ```bash
   cp env.example .env
   ```
   
   Edit `.env`:
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=postgres
   DB_NAME=scp_platform
   JWT_SECRET=your-secret-key-change-in-production
   ```

3. **Create database**:
   ```bash
   createdb scp_platform
   ```

4. **Run migrations**:
   ```bash
   for migration in migrations/*.sql; do
     psql -U postgres -d scp_platform -f "$migration"
   done
   ```

5. **Run server**:
   ```bash
   go run cmd/api/main.go
   ```

### Docker Setup

```bash
docker-compose up -d
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `DB_NAME` | Database name | `scp_platform` |
| `JWT_SECRET` | JWT signing secret | (required) |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:3000,...` |

## Key API Endpoints (MVP)

### Authentication
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/auth/me` - Get current user

### Consumer
- `GET /api/v1/consumer/suppliers` - List suppliers
- `POST /api/v1/suppliers/:id/link-request` - Request supplier link
- `GET /api/v1/consumer/products` - Get products
- `POST /api/v1/consumer/orders` - Create order
- `GET /api/v1/consumer/orders` - Get orders

### Supplier
- `GET /api/v1/supplier/products` - List products
- `POST /api/v1/supplier/products` - Create product
- `PUT /api/v1/supplier/products/:id` - Update product
- `GET /api/v1/supplier/orders` - Get orders
- `POST /api/v1/supplier/orders/:id/accept` - Accept order
- `POST /api/v1/supplier/consumer-links/:id/approve` - Approve link

### WebSocket
- `WS /api/v1/ws` - Real-time messaging

## Authentication

Include JWT token in Authorization header:
```
Authorization: Bearer <access_token>
```

## Roles

| Role | Access |
|------|--------|
| `consumer` | Consumer endpoints |
| `owner` | Full supplier management |
| `manager` | Supplier management (no user management) |
| `sales_rep` | Conversations, complaints, order viewing |

## Testing

```bash
go test ./...
```

## Production

1. Generate strong `JWT_SECRET`: `openssl rand -hex 32`
2. Set `DB_SSLMODE=require` for database
3. Configure CORS origins properly
4. Use reverse proxy (nginx) for SSL

---

For complete API documentation, see [Backend Integration Guide](../docs/BACKEND_INTEGRATION_GUIDE.md).
