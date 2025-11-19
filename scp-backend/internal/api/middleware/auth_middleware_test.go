package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/scp-platform/backend/pkg/jwt"
)

func TestAuthMiddleware_MissingHeader(t *testing.T) {
	gin.SetMode(gin.TestMode)

	jwtService := jwt.NewJWTService("test-secret", 60, 7)
	middleware := AuthMiddleware(jwtService)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)

	middleware(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuthMiddleware_InvalidFormat(t *testing.T) {
	gin.SetMode(gin.TestMode)

	jwtService := jwt.NewJWTService("test-secret", 60, 7)
	middleware := AuthMiddleware(jwtService)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Authorization", "InvalidFormat token")

	middleware(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuthMiddleware_InvalidToken(t *testing.T) {
	gin.SetMode(gin.TestMode)

	jwtService := jwt.NewJWTService("test-secret", 60, 7)
	middleware := AuthMiddleware(jwtService)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Authorization", "Bearer invalid-token")

	middleware(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAuthMiddleware_ValidToken(t *testing.T) {
	gin.SetMode(gin.TestMode)

	jwtService := jwt.NewJWTService("test-secret", 60, 7)
	token, _, err := jwtService.GenerateTokens("user-123", "test@example.com", "consumer", nil)
	assert.NoError(t, err)

	middleware := AuthMiddleware(jwtService)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Authorization", "Bearer "+token)

	middleware(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "user-123", c.GetString("user_id"))
	assert.Equal(t, "test@example.com", c.GetString("email"))
	assert.Equal(t, "consumer", c.GetString("role"))
}

func TestAuthMiddleware_WithSupplierID(t *testing.T) {
	gin.SetMode(gin.TestMode)

	jwtService := jwt.NewJWTService("test-secret", 60, 7)
	supplierID := "supplier-123"
	token, _, err := jwtService.GenerateTokens("user-123", "test@example.com", "owner", &supplierID)
	assert.NoError(t, err)

	middleware := AuthMiddleware(jwtService)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Authorization", "Bearer "+token)

	middleware(c)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, supplierID, c.GetString("supplier_id"))
}

func TestRequireRole_Allowed(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := RequireRole("consumer", "owner")

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("role", "consumer")

	middleware(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRequireRole_Forbidden(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := RequireRole("owner", "manager")

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("role", "consumer")

	middleware(c)

	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestRequireRole_NoRole(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := RequireRole("consumer")

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	middleware(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestRequireSupplier_WithSupplierID(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := RequireSupplier()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("supplier_id", "supplier-123")
	c.Set("role", "owner")

	middleware(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRequireSupplier_WithoutSupplierID_Owner(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := RequireSupplier()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("role", "owner")

	middleware(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRequireSupplier_WithoutSupplierID_Consumer(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := RequireSupplier()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("role", "consumer")

	middleware(c)

	assert.Equal(t, http.StatusForbidden, w.Code)
}

