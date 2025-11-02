# Backend Integration Guide - SCP Platform

**Version:** 1.0  
**Last Updated:** December 2024  
**Target Backend:** Go (Golang)  
**Frontend Applications:** Flutter Mobile Apps + Next.js Web Portal

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [API Structure](#api-structure)
4. [Authentication & Authorization](#authentication--authorization)
5. [Data Models & Schemas](#data-models--schemas)
6. [Go Backend Implementation](#go-backend-implementation)
7. [API Endpoints Specification](#api-endpoints-specification)
8. [Real-time Features (WebSocket)](#real-time-features-websocket)
9. [File Upload Handling](#file-upload-handling)
10. [Error Handling](#error-handling)
11. [Testing & Validation](#testing--validation)
12. [Deployment Configuration](#deployment-configuration)

---

## Overview

The SCP Platform consists of:
- **Consumer Mobile App** (Flutter) - For restaurants and hotels
- **Supplier Sales Mobile App** (Flutter) - For sales representatives
- **Supplier Web Portal** (Next.js) - For suppliers (owners/managers)

All three applications connect to a single REST API backend. This guide provides complete integration specifications for implementing the backend in Go.

---

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend Applications                 │
├──────────────────┬──────────────────┬──────────────────┤
│ Consumer App     │ Supplier App     │ Supplier Web      │
│ (Flutter)        │ (Flutter)        │ (Next.js)         │
└────────┬─────────┴────────┬─────────┴────────┬──────────┘
         │                   │                  │
         └───────────────────┼──────────────────┘
                             │
                    ┌────────▼─────────┐
                    │   REST API       │
                    │   (Go Backend)   │
                    └────────┬─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────▼────┐       ┌─────▼─────┐       ┌─────▼─────┐
    │ Database │       │  Redis    │       │ WebSocket │
    │ (PostgreSQL)│   │ (Cache/Session)│   │ (Real-time)│
    └──────────┘       └───────────┘       └───────────┘
```

### API Base URLs

**Production:** `https://api.scp-platform.com/api/v1`  
**Staging:** `https://staging-api.scp-platform.com/api/v1`  
**Development:** `https://dev-api.scp-platform.com/api/v1` or `http://localhost:3000/api/v1`

---

## API Structure

### Standard Response Format

All API responses should follow this structure:

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {}
  }
}
```

### HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Validation Error
- `500` - Internal Server Error

### Pagination

All list endpoints should support pagination:

```
GET /api/v1/resource?page=1&page_size=20
```

**Response:**
```json
{
  "results": [...],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

---

## Authentication & Authorization

### JWT Token Authentication

All authenticated requests require a Bearer token in the Authorization header:

```
Authorization: Bearer <access_token>
```

### Authentication Flow

1. **Login** - `POST /api/v1/auth/login`
2. **Token Refresh** - `POST /api/v1/auth/refresh`
3. **Get Current User** - `GET /api/v1/auth/me`
4. **Logout** - `POST /api/v1/auth/logout`

### Role-Based Access Control (RBAC)

**User Roles:**
- `consumer` - Restaurant/Hotel owner (mobile app)
- `owner` - Supplier owner (web portal)
- `manager` - Supplier manager (web portal)
- `sales_rep` - Sales representative (mobile app)

**Permission Matrix:**

| Endpoint | Consumer | Owner | Manager | Sales Rep |
|----------|----------|-------|---------|-----------|
| `/consumer/*` | ✅ | ❌ | ❌ | ❌ |
| `/supplier/products` | ❌ | ✅ | ✅ | ❌ |
| `/supplier/users` | ❌ | ✅ | ❌ | ❌ |
| `/supplier/complaints` | ❌ | ✅ | ✅ | ✅ |
| `/supplier/complaints/:id/escalate` | ❌ | ❌ | ❌ | ✅ |

### Token Structure

**Access Token (JWT):**
```json
{
  "user_id": "uuid",
  "email": "user@example.com",
  "role": "consumer|owner|manager|sales_rep",
  "supplier_id": "uuid (if supplier role)",
  "exp": 1234567890
}
```

**Token Expiry:**
- Access Token: 15 minutes
- Refresh Token: 7 days

---

## Data Models & Schemas

### Core Models

#### User Model

**Go Struct:**
```go
// File: internal/models/user.go
type User struct {
    ID            string    `json:"id" db:"id"`
    Email         string    `json:"email" db:"email"`
    PasswordHash  string    `json:"-" db:"password_hash"`
    FirstName     *string   `json:"first_name" db:"first_name"`
    LastName      *string   `json:"last_name" db:"last_name"`
    CompanyName   *string   `json:"company_name" db:"company_name"`
    PhoneNumber   *string   `json:"phone_number" db:"phone_number"`
    Role          string    `json:"role" db:"role"`
    ProfileImageURL *string `json:"profile_image_url" db:"profile_image_url"`
    SupplierID    *string  `json:"supplier_id" db:"supplier_id"`
    CreatedAt     time.Time `json:"created_at" db:"created_at"`
    UpdatedAt     *time.Time `json:"updated_at" db:"updated_at"`
}
```

**Database Schema:**
```sql
-- File: migrations/001_create_users.sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company_name VARCHAR(255),
    phone_number VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('consumer', 'owner', 'manager', 'sales_rep')),
    profile_image_url TEXT,
    supplier_id UUID REFERENCES suppliers(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_supplier_id (supplier_id)
);
```

#### Product Model

**Go Struct:**
```go
// File: internal/models/product.go
type Product struct {
    ID              string     `json:"id" db:"id"`
    Name            string     `json:"name" db:"name"`
    Description     *string    `json:"description" db:"description"`
    ImageURL        *string    `json:"image_url" db:"image_url"`
    Unit            string     `json:"unit" db:"unit"`
    Price           float64    `json:"price" db:"price"`
    Discount        *float64   `json:"discount" db:"discount"`
    StockLevel      int        `json:"stock_level" db:"stock_level"`
    MinOrderQuantity int       `json:"min_order_quantity" db:"min_order_quantity"`
    SupplierID      string     `json:"supplier_id" db:"supplier_id"`
    CreatedAt       time.Time  `json:"created_at" db:"created_at"`
    UpdatedAt       *time.Time `json:"updated_at" db:"updated_at"`
}
```

#### Order Model

**Go Struct:**
```go
// File: internal/models/order.go
type Order struct {
    ID            string      `json:"id" db:"id"`
    ConsumerID    string      `json:"consumer_id" db:"consumer_id"`
    SupplierID   string      `json:"supplier_id" db:"supplier_id"`
    Status       string      `json:"status" db:"status"`
    Subtotal     float64     `json:"subtotal" db:"subtotal"`
    Tax          float64     `json:"tax" db:"tax"`
    ShippingFee  float64     `json:"shipping_fee" db:"shipping_fee"`
    Total        float64     `json:"total" db:"total"`
    Items        []OrderItem `json:"items"`
    CreatedAt    time.Time   `json:"created_at" db:"created_at"`
    UpdatedAt    *time.Time  `json:"updated_at" db:"updated_at"`
}

type OrderItem struct {
    ID          string  `json:"id" db:"id"`
    OrderID    string  `json:"order_id" db:"order_id"`
    ProductID  string  `json:"product_id" db:"product_id"`
    Quantity   int     `json:"quantity" db:"quantity"`
    UnitPrice  float64 `json:"unit_price" db:"unit_price"`
    Subtotal   float64 `json:"subtotal" db:"subtotal"`
}
```

#### Consumer Link Model

**Go Struct:**
```go
// File: internal/models/consumer_link.go
type ConsumerLink struct {
    ID          string     `json:"id" db:"id"`
    ConsumerID  string     `json:"consumer_id" db:"consumer_id"`
    SupplierID string     `json:"supplier_id" db:"supplier_id"`
    Status     string     `json:"status" db:"status"`
    RequestedAt time.Time `json:"requested_at" db:"requested_at"`
    ApprovedAt *time.Time `json:"approved_at" db:"approved_at"`
}
```

#### Complaint Model

**Go Struct:**
```go
// File: internal/models/complaint.go
type Complaint struct {
    ID           string     `json:"id" db:"id"`
    ConversationID string   `json:"conversation_id" db:"conversation_id"`
    ConsumerID   string     `json:"consumer_id" db:"consumer_id"`
    OrderID      *string    `json:"order_id" db:"order_id"`
    Title        string     `json:"title" db:"title"`
    Description  string     `json:"description" db:"description"`
    Priority     string     `json:"priority" db:"priority"`
    Status       string     `json:"status" db:"status"`
    EscalatedBy  *string    `json:"escalated_by" db:"escalated_by"`
    EscalatedAt  *time.Time `json:"escalated_at" db:"escalated_at"`
    ResolvedAt   *time.Time `json:"resolved_at" db:"resolved_at"`
    Resolution   *string    `json:"resolution" db:"resolution"`
    CreatedAt    time.Time  `json:"created_at" db:"created_at"`
}
```

---

## Go Backend Implementation

### Recommended Project Structure

```
scp-backend/
├── cmd/
│   └── api/
│       └── main.go                 # Application entry point
├── internal/
│   ├── api/
│   │   ├── handlers/               # HTTP handlers
│   │   │   ├── auth_handler.go
│   │   │   ├── product_handler.go
│   │   │   ├── order_handler.go
│   │   │   ├── consumer_handler.go
│   │   │   ├── complaint_handler.go
│   │   │   └── dashboard_handler.go
│   │   ├── middleware/             # Middleware functions
│   │   │   ├── auth_middleware.go
│   │   │   ├── cors_middleware.go
│   │   │   └── logging_middleware.go
│   │   └── routes.go               # Route definitions
│   ├── models/                     # Data models
│   │   ├── user.go
│   │   ├── product.go
│   │   ├── order.go
│   │   ├── consumer_link.go
│   │   └── complaint.go
│   ├── services/                    # Business logic
│   │   ├── auth_service.go
│   │   ├── product_service.go
│   │   ├── order_service.go
│   │   └── notification_service.go
│   ├── repository/                  # Data access layer
│   │   ├── user_repository.go
│   │   ├── product_repository.go
│   │   └── order_repository.go
│   └── config/                      # Configuration
│       └── config.go
├── pkg/
│   ├── jwt/                         # JWT utilities
│   │   └── jwt.go
│   ├── password/                    # Password hashing
│   │   └── password.go
│   └── validator/                   # Input validation
│       └── validator.go
├── migrations/                      # Database migrations
│   ├── 001_create_users.sql
│   ├── 002_create_products.sql
│   └── ...
├── docker-compose.yml
├── Dockerfile
├── go.mod
├── go.sum
└── README.md
```

### Key Dependencies

**go.mod:**
```go
module github.com/scp-platform/backend

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1        // Web framework
    github.com/golang-jwt/jwt/v5 v5.2.0     // JWT
    github.com/lib/pq v1.10.9               // PostgreSQL driver
    github.com/jmoiron/sqlx v1.3.5           // SQL extensions
    golang.org/x/crypto v0.17.0            // Password hashing
    github.com/google/uuid v1.5.0          // UUID generation
    github.com/go-redis/redis/v8 v8.11.5   // Redis client
    github.com/gorilla/websocket v1.5.1    // WebSocket
)
```

### Configuration File

**File: `internal/config/config.go`**
```go
package config

import (
    "os"
    "strconv"
)

type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    JWT      JWTConfig
    Redis    RedisConfig
}

type ServerConfig struct {
    Port         string
    Environment  string
    CORSOrigins  []string
}

type DatabaseConfig struct {
    Host     string
    Port     int
    User     string
    Password string
    DBName   string
    SSLMode  string
}

type JWTConfig struct {
    SecretKey     string
    AccessExpiry  int // minutes
    RefreshExpiry int // days
}

type RedisConfig struct {
    Host     string
    Port     int
    Password string
}

func Load() *Config {
    return &Config{
        Server: ServerConfig{
            Port:        getEnv("PORT", "3000"),
            Environment: getEnv("ENV", "development"),
            CORSOrigins: []string{
                "http://localhost:3000",
                "http://localhost:3001",
                "https://supplier.scp-platform.com",
            },
        },
        Database: DatabaseConfig{
            Host:     getEnv("DB_HOST", "localhost"),
            Port:     getIntEnv("DB_PORT", 5432),
            User:     getEnv("DB_USER", "postgres"),
            Password: getEnv("DB_PASSWORD", ""),
            DBName:   getEnv("DB_NAME", "scp_platform"),
            SSLMode:  getEnv("DB_SSLMODE", "disable"),
        },
        JWT: JWTConfig{
            SecretKey:     getEnv("JWT_SECRET", "change-me-in-production"),
            AccessExpiry:  getIntEnv("JWT_ACCESS_EXPIRY", 15),
            RefreshExpiry: getIntEnv("JWT_REFRESH_EXPIRY", 7),
        },
        Redis: RedisConfig{
            Host:     getEnv("REDIS_HOST", "localhost"),
            Port:     getIntEnv("REDIS_PORT", 6379),
            Password: getEnv("REDIS_PASSWORD", ""),
        },
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if intValue, err := strconv.Atoi(value); err == nil {
            return intValue
        }
    }
    return defaultValue
}
```

---

## API Endpoints Specification

### Authentication Endpoints

#### 1. Login
**File:** `internal/api/handlers/auth_handler.go`

```go
// POST /api/v1/auth/login
func LoginHandler(c *gin.Context) {
    var req struct {
        Email    string `json:"email" binding:"required,email"`
        Password string `json:"password" binding:"required,min=8"`
        Role     string `json:"role" binding:"required,oneof=consumer supplier"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    // Validate user credentials
    user, err := authService.Authenticate(req.Email, req.Password, req.Role)
    if err != nil {
        c.JSON(401, gin.H{"error": "Invalid credentials"})
        return
    }
    
    // Generate tokens
    accessToken, refreshToken, err := jwtService.GenerateTokens(user)
    if err != nil {
        c.JSON(500, gin.H{"error": "Failed to generate tokens"})
        return
    }
    
    c.JSON(200, gin.H{
        "access_token": accessToken,
        "refresh_token": refreshToken,
        "user": user,
    })
}
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "consumer"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "consumer",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

#### 2. Get Current User
**File:** `internal/api/handlers/auth_handler.go`

```go
// GET /api/v1/auth/me
func GetCurrentUserHandler(c *gin.Context) {
    userID := c.GetString("user_id") // From auth middleware
    
    user, err := userRepository.GetByID(userID)
    if err != nil {
        c.JSON(404, gin.H{"error": "User not found"})
        return
    }
    
    c.JSON(200, gin.H{"user": user})
}
```

#### 3. Refresh Token
**File:** `internal/api/handlers/auth_handler.go`

```go
// POST /api/v1/auth/refresh
func RefreshTokenHandler(c *gin.Context) {
    var req struct {
        RefreshToken string `json:"refresh_token" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    claims, err := jwtService.ValidateRefreshToken(req.RefreshToken)
    if err != nil {
        c.JSON(401, gin.H{"error": "Invalid refresh token"})
        return
    }
    
    user, err := userRepository.GetByID(claims.UserID)
    if err != nil {
        c.JSON(404, gin.H{"error": "User not found"})
        return
    }
    
    accessToken, _, err := jwtService.GenerateTokens(user)
    if err != nil {
        c.JSON(500, gin.H{"error": "Failed to generate token"})
        return
    }
    
    c.JSON(200, gin.H{"access_token": accessToken})
}
```

#### 4. Logout
**File:** `internal/api/handlers/auth_handler.go`

```go
// POST /api/v1/auth/logout
func LogoutHandler(c *gin.Context) {
    tokenID := c.GetString("token_id") // JWT ID
    
    // Invalidate token in Redis
    redisClient.Del(ctx, fmt.Sprintf("token:%s", tokenID))
    
    c.JSON(200, gin.H{"message": "Logged out successfully"})
}
```

### Product Endpoints (Supplier)

#### 1. Get Products
**File:** `internal/api/handlers/product_handler.go`

```go
// GET /api/v1/supplier/products
func GetProductsHandler(c *gin.Context) {
    supplierID := c.GetString("supplier_id")
    page := c.DefaultQuery("page", "1")
    pageSize := c.DefaultQuery("page_size", "20")
    
    products, total, err := productRepository.GetBySupplier(
        supplierID, page, pageSize)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, gin.H{
        "results": products,
        "pagination": gin.H{
            "page": page,
            "page_size": pageSize,
            "total": total,
            "total_pages": (total + pageSize - 1) / pageSize,
        },
    })
}
```

#### 2. Create Product
**File:** `internal/api/handlers/product_handler.go`

```go
// POST /api/v1/supplier/products
func CreateProductHandler(c *gin.Context) {
    supplierID := c.GetString("supplier_id")
    
    var req struct {
        Name            string   `json:"name" binding:"required"`
        Description     *string  `json:"description"`
        ImageURL        *string  `json:"image_url"`
        Unit            string   `json:"unit" binding:"required"`
        Price           float64  `json:"price" binding:"required,gt=0"`
        Discount        *float64 `json:"discount"`
        StockLevel      int      `json:"stock_level" binding:"gte=0"`
        MinOrderQuantity int     `json:"min_order_quantity" binding:"gte=1"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    product := &models.Product{
        ID:              uuid.New().String(),
        Name:            req.Name,
        Description:     req.Description,
        ImageURL:        req.ImageURL,
        Unit:            req.Unit,
        Price:           req.Price,
        Discount:        req.Discount,
        StockLevel:      req.StockLevel,
        MinOrderQuantity: req.MinOrderQuantity,
        SupplierID:      supplierID,
        CreatedAt:       time.Now(),
    }
    
    if err := productRepository.Create(product); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(201, product)
}
```

#### 3. Update Product
**File:** `internal/api/handlers/product_handler.go`

```go
// PUT /api/v1/supplier/products/:id
func UpdateProductHandler(c *gin.Context) {
    productID := c.Param("id")
    supplierID := c.GetString("supplier_id")
    
    // Verify ownership
    product, err := productRepository.GetByID(productID)
    if err != nil || product.SupplierID != supplierID {
        c.JSON(404, gin.H{"error": "Product not found"})
        return
    }
    
    var req struct {
        Name            *string  `json:"name"`
        Description     *string  `json:"description"`
        ImageURL        *string  `json:"image_url"`
        Unit            *string  `json:"unit"`
        Price           *float64 `json:"price"`
        Discount        *float64 `json:"discount"`
        StockLevel      *int     `json:"stock_level"`
        MinOrderQuantity *int    `json:"min_order_quantity"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    // Update fields
    if req.Name != nil {
        product.Name = *req.Name
    }
    // ... update other fields
    
    if err := productRepository.Update(product); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, product)
}
```

#### 4. Delete Product
**File:** `internal/api/handlers/product_handler.go`

```go
// DELETE /api/v1/supplier/products/:id
func DeleteProductHandler(c *gin.Context) {
    productID := c.Param("id")
    supplierID := c.GetString("supplier_id")
    
    // Verify ownership
    product, err := productRepository.GetByID(productID)
    if err != nil || product.SupplierID != supplierID {
        c.JSON(404, gin.H{"error": "Product not found"})
        return
    }
    
    if err := productRepository.Delete(productID); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, gin.H{"message": "Product deleted"})
}
```

#### 5. Bulk Update Products
**File:** `internal/api/handlers/product_handler.go`

```go
// POST /api/v1/supplier/products/bulk-update
func BulkUpdateProductsHandler(c *gin.Context) {
    supplierID := c.GetString("supplier_id")
    
    var req struct {
        ProductIDs []string `json:"product_ids" binding:"required"`
        Updates    struct {
            Price      *float64 `json:"price"`
            StockLevel *int     `json:"stock_level"`
            Discount   *float64 `json:"discount"`
        } `json:"updates" binding:"required"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    products, err := productRepository.BulkUpdate(
        supplierID, req.ProductIDs, req.Updates)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, products)
}
```

### Order Endpoints

#### 1. Create Order (Consumer)
**File:** `internal/api/handlers/order_handler.go`

```go
// POST /api/v1/consumer/orders
func CreateOrderHandler(c *gin.Context) {
    consumerID := c.GetString("user_id")
    
    var req struct {
        SupplierID string `json:"supplier_id" binding:"required"`
        Items      []struct {
            ProductID string `json:"product_id" binding:"required"`
            Quantity  int    `json:"quantity" binding:"required,gt=0"`
        } `json:"items" binding:"required,min=1"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    // Validate consumer-supplier link
    link, err := consumerLinkRepository.GetByConsumerAndSupplier(
        consumerID, req.SupplierID)
    if err != nil || link.Status != "approved" {
        c.JSON(403, gin.H{"error": "Supplier link not approved"})
        return
    }
    
    // Calculate totals
    order, err := orderService.CreateOrder(consumerID, req.SupplierID, req.Items)
    if err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(201, order)
}
```

#### 2. Accept Order (Supplier)
**File:** `internal/api/handlers/order_handler.go`

```go
// POST /api/v1/supplier/orders/:id/accept
func AcceptOrderHandler(c *gin.Context) {
    orderID := c.Param("id")
    supplierID := c.GetString("supplier_id")
    
    order, err := orderRepository.GetByID(orderID)
    if err != nil || order.SupplierID != supplierID {
        c.JSON(404, gin.H{"error": "Order not found"})
        return
    }
    
    if order.Status != "pending" {
        c.JSON(400, gin.H{"error": "Order cannot be accepted"})
        return
    }
    
    // Update stock levels
    for _, item := range order.Items {
        if err := productRepository.DecrementStock(
            item.ProductID, item.Quantity); err != nil {
            c.JSON(400, gin.H{"error": "Insufficient stock"})
            return
        }
    }
    
    order.Status = "accepted"
    order.UpdatedAt = &time.Now()
    
    if err := orderRepository.Update(order); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    // Emit WebSocket event
    websocketService.NotifyOrderUpdate(order)
    
    c.JSON(200, order)
}
```

### Consumer Link Endpoints

#### 1. Request Link (Consumer)
**File:** `internal/api/handlers/consumer_handler.go`

```go
// POST /api/v1/suppliers/:id/link-request
func RequestLinkHandler(c *gin.Context) {
    supplierID := c.Param("id")
    consumerID := c.GetString("user_id")
    
    var req struct {
        Message *string `json:"message"`
    }
    
    link := &models.ConsumerLink{
        ID:          uuid.New().String(),
        ConsumerID: consumerID,
        SupplierID: supplierID,
        Status:     "pending",
        RequestedAt: time.Now(),
    }
    
    if err := consumerLinkRepository.Create(link); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(201, link)
}
```

#### 2. Approve/Reject Link (Supplier)
**File:** `internal/api/handlers/consumer_handler.go`

```go
// POST /api/v1/supplier/consumer-links/:id/approve
func ApproveLinkHandler(c *gin.Context) {
    linkID := c.Param("id")
    supplierID := c.GetString("supplier_id")
    
    link, err := consumerLinkRepository.GetByID(linkID)
    if err != nil || link.SupplierID != supplierID {
        c.JSON(404, gin.H{"error": "Link not found"})
        return
    }
    
    link.Status = "approved"
    now := time.Now()
    link.ApprovedAt = &now
    
    if err := consumerLinkRepository.Update(link); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, link)
}
```

### Complaint Endpoints

#### 1. Log Complaint (Sales Rep)
**File:** `internal/api/handlers/complaint_handler.go`

```go
// POST /api/v1/supplier/complaints
func LogComplaintHandler(c *gin.Context) {
    salesRepID := c.GetString("user_id")
    
    var req struct {
        ConversationID string `json:"conversation_id" binding:"required"`
        ConsumerID     string `json:"consumer_id" binding:"required"`
        OrderID        *string `json:"order_id"`
        Title          string  `json:"title" binding:"required"`
        Description    string  `json:"description" binding:"required"`
        Priority       string  `json:"priority" binding:"required,oneof=low medium high urgent"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    complaint := &models.Complaint{
        ID:            uuid.New().String(),
        ConversationID: req.ConversationID,
        ConsumerID:    req.ConsumerID,
        OrderID:       req.OrderID,
        Title:         req.Title,
        Description:   req.Description,
        Priority:      req.Priority,
        Status:        "open",
        CreatedAt:     time.Now(),
    }
    
    if err := complaintRepository.Create(complaint); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(201, complaint)
}
```

#### 2. Escalate Complaint
**File:** `internal/api/handlers/complaint_handler.go`

```go
// POST /api/v1/supplier/complaints/:id/escalate
func EscalateComplaintHandler(c *gin.Context) {
    complaintID := c.Param("id")
    salesRepID := c.GetString("user_id")
    
    complaint, err := complaintRepository.GetByID(complaintID)
    if err != nil {
        c.JSON(404, gin.H{"error": "Complaint not found"})
        return
    }
    
    complaint.Status = "escalated"
    complaint.EscalatedBy = &salesRepID
    now := time.Now()
    complaint.EscalatedAt = &now
    
    if err := complaintRepository.Update(complaint); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    // Notify managers/owners via WebSocket
    websocketService.NotifyComplaintEscalation(complaint)
    
    c.JSON(200, complaint)
}
```

#### 3. Resolve Complaint
**File:** `internal/api/handlers/complaint_handler.go`

```go
// POST /api/v1/supplier/complaints/:id/resolve
func ResolveComplaintHandler(c *gin.Context) {
    complaintID := c.Param("id")
    
    var req struct {
        Resolution string `json:"resolution" binding:"required,min=10"`
    }
    
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    complaint, err := complaintRepository.GetByID(complaintID)
    if err != nil {
        c.JSON(404, gin.H{"error": "Complaint not found"})
        return
    }
    
    complaint.Status = "resolved"
    complaint.Resolution = &req.Resolution
    now := time.Now()
    complaint.ResolvedAt = &now
    
    if err := complaintRepository.Update(complaint); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, complaint)
}
```

### Dashboard Endpoints

#### Get Dashboard Stats (Supplier)
**File:** `internal/api/handlers/dashboard_handler.go`

```go
// GET /api/v1/supplier/dashboard/stats
func GetDashboardStatsHandler(c *gin.Context) {
    supplierID := c.GetString("supplier_id")
    
    stats, err := dashboardService.GetStats(supplierID)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(200, stats)
}
```

**Response:**
```json
{
  "total_orders": 150,
  "pending_orders": 12,
  "pending_link_requests": 5,
  "low_stock_items": 8,
  "recent_orders": [...],
  "low_stock_products": [...]
}
```

---

## Real-time Features (WebSocket)

### WebSocket Setup

**File:** `internal/api/handlers/websocket_handler.go`

```go
var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool {
        return true // Configure properly for production
    },
}

func WebSocketHandler(c *gin.Context) {
    conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
    if err != nil {
        return
    }
    defer conn.Close()
    
    userID := c.GetString("user_id")
    role := c.GetString("role")
    
    // Register client
    client := &WebSocketClient{
        ID:     userID,
        Role:   role,
        Conn:   conn,
        Send:   make(chan []byte, 256),
    }
    
    hub.Register(client)
    go client.WritePump()
    client.ReadPump()
}

func (hub *Hub) NotifyOrderUpdate(order *models.Order) {
    message := websocket.Message{
        Type: "order_updated",
        Data: order,
    }
    
    // Send to supplier
    hub.SendToSupplier(order.SupplierID, message)
    
    // Send to consumer
    hub.SendToConsumer(order.ConsumerID, message)
}
```

---

## File Upload Handling

### Image Upload Endpoint

**File:** `internal/api/handlers/upload_handler.go`

```go
// POST /api/v1/upload
func UploadHandler(c *gin.Context) {
    file, err := c.FormFile("file")
    if err != nil {
        c.JSON(400, gin.H{"error": "File required"})
        return
    }
    
    // Validate file type and size
    if !isValidImage(file) {
        c.JSON(400, gin.H{"error": "Invalid file type"})
        return
    }
    
    // Upload to S3 or local storage
    url, err := storageService.Upload(file)
    if err != nil {
        c.JSON(500, gin.H{"error": "Upload failed"})
        return
    }
    
    c.JSON(200, gin.H{"url": url})
}
```

---

## Error Handling

### Standard Error Format

**File:** `pkg/errors/errors.go`

```go
type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details map[string]interface{} `json:"details,omitempty"`
}

func (e *APIError) Error() string {
    return e.Message
}

func NewValidationError(field, message string) *APIError {
    return &APIError{
        Code:    "VALIDATION_ERROR",
        Message: message,
        Details: map[string]interface{}{
            "field": field,
        },
    }
}
```

---

## Testing & Validation

### Environment Variables

**File:** `.env.example`

```env
# Server
PORT=3000
ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=scp_platform
DB_SSLMODE=disable

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_ACCESS_EXPIRY=15
JWT_REFRESH_EXPIRY=7

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# File Storage
STORAGE_TYPE=local # or s3
S3_BUCKET=scp-platform-uploads
AWS_REGION=us-east-1
```

---

## Deployment Configuration

### Docker Compose

**File:** `docker-compose.yml`

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: scp_platform
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Integration Checklist

### Phase 1: Core Infrastructure
- [ ] Set up Go project structure
- [ ] Configure database (PostgreSQL)
- [ ] Set up Redis for caching/sessions
- [ ] Implement JWT authentication
- [ ] Create database migrations
- [ ] Set up middleware (CORS, auth, logging)

### Phase 2: Authentication
- [ ] Implement login endpoint
- [ ] Implement token refresh
- [ ] Implement logout with token invalidation
- [ ] Add RBAC middleware
- [ ] Test authentication flow

### Phase 3: Core Features
- [ ] User management (CRUD)
- [ ] Product management (supplier)
- [ ] Order management
- [ ] Consumer link management
- [ ] Complaint system

### Phase 4: Advanced Features
- [ ] WebSocket implementation
- [ ] File upload handling
- [ ] Dashboard stats endpoint
- [ ] Bulk operations
- [ ] Real-time notifications

### Phase 5: Testing & Deployment
- [ ] Unit tests
- [ ] Integration tests
- [ ] API documentation (Swagger)
- [ ] Docker containerization
- [ ] CI/CD pipeline

---

## Additional Resources

### API Documentation
- Generate Swagger docs using `swag` library
- File: `cmd/api/swagger.go`

### Logging
- Use structured logging (logrus or zap)
- File: `pkg/logger/logger.go`

### Database Migrations
- Use `golang-migrate` or `gormigrate`
- Migrations directory: `migrations/`

### Testing
- Unit tests: `*_test.go` files
- Integration tests: `tests/integration/`

---

**End of Integration Guide**

For questions or clarifications, refer to the frontend code implementations in:
- `scp-mobile-shared/lib/services/` - API service calls
- `scp-supplier-web/lib/api/` - Web portal API calls

