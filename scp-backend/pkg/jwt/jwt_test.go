package jwt

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestNewJWTService(t *testing.T) {
	service := NewJWTService("test-secret", 60, 7)
	assert.NotNil(t, service)
	assert.Equal(t, "test-secret", service.secretKey)
	assert.Equal(t, 60*time.Minute, service.accessExpiry)
	assert.Equal(t, 7*24*time.Hour, service.refreshExpiry)
}

func TestJWTService_GenerateTokens(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)
	supplierID := "supplier-123"

	accessToken, refreshToken, err := service.GenerateTokens("user-123", "test@example.com", "consumer", &supplierID)
	assert.NoError(t, err)
	assert.NotEmpty(t, accessToken)
	assert.NotEmpty(t, refreshToken)
	assert.NotEqual(t, accessToken, refreshToken)
}

func TestJWTService_GenerateTokens_WithoutSupplierID(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)

	accessToken, refreshToken, err := service.GenerateTokens("user-123", "test@example.com", "consumer", nil)
	assert.NoError(t, err)
	assert.NotEmpty(t, accessToken)
	assert.NotEmpty(t, refreshToken)
}

func TestJWTService_ValidateToken(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)
	supplierID := "supplier-123"

	accessToken, _, err := service.GenerateTokens("user-123", "test@example.com", "consumer", &supplierID)
	assert.NoError(t, err)

	claims, err := service.ValidateToken(accessToken)
	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, "user-123", claims.UserID)
	assert.Equal(t, "test@example.com", claims.Email)
	assert.Equal(t, "consumer", claims.Role)
	assert.NotNil(t, claims.SupplierID)
	assert.Equal(t, "supplier-123", *claims.SupplierID)
}

func TestJWTService_ValidateToken_InvalidToken(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)

	claims, err := service.ValidateToken("invalid-token")
	assert.Error(t, err)
	assert.Nil(t, claims)
}

func TestJWTService_ValidateToken_WrongSecret(t *testing.T) {
	service1 := NewJWTService("secret-1", 60, 7)
	service2 := NewJWTService("secret-2", 60, 7)

	token, _, err := service1.GenerateTokens("user-123", "test@example.com", "consumer", nil)
	assert.NoError(t, err)

	claims, err := service2.ValidateToken(token)
	assert.Error(t, err)
	assert.Nil(t, claims)
}

func TestJWTService_ValidateToken_ExpiredToken(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", -1, 7) // Negative expiry = expired immediately

	token, _, err := service.GenerateTokens("user-123", "test@example.com", "consumer", nil)
	assert.NoError(t, err)

	// Wait a bit to ensure token is expired
	time.Sleep(100 * time.Millisecond)

	claims, err := service.ValidateToken(token)
	assert.Error(t, err)
	assert.Nil(t, claims)
}

func TestJWTService_ValidateRefreshToken(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)

	_, refreshToken, err := service.GenerateTokens("user-123", "test@example.com", "consumer", nil)
	assert.NoError(t, err)

	claims, err := service.ValidateRefreshToken(refreshToken)
	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, "user-123", claims.UserID)
}

func TestJWTService_ValidateRefreshToken_InvalidToken(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)

	claims, err := service.ValidateRefreshToken("invalid-token")
	assert.Error(t, err)
	assert.Nil(t, claims)
}

func TestJWTService_TokenClaims(t *testing.T) {
	service := NewJWTService("test-secret-key-12345", 60, 7)

	accessToken, _, err := service.GenerateTokens("user-123", "test@example.com", "owner", nil)
	assert.NoError(t, err)

	claims, err := service.ValidateToken(accessToken)
	assert.NoError(t, err)
	assert.Equal(t, "user-123", claims.UserID)
	assert.Equal(t, "test@example.com", claims.Email)
	assert.Equal(t, "owner", claims.Role)
	assert.Equal(t, "scp-platform", claims.Issuer)
	assert.Equal(t, "user-123", claims.Subject)
}

