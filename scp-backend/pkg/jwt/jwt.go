package jwt

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type Claims struct {
	UserID     string `json:"user_id"`
	Email      string `json:"email"`
	Role       string `json:"role"`
	SupplierID *string `json:"supplier_id,omitempty"`
	jwt.RegisteredClaims
}

type JWTService struct {
	secretKey      string
	accessExpiry   time.Duration
	refreshExpiry  time.Duration
}

func NewJWTService(secretKey string, accessExpiryMinutes, refreshExpiryDays int) *JWTService {
	return &JWTService{
		secretKey:     secretKey,
		accessExpiry:  time.Duration(accessExpiryMinutes) * time.Minute,
		refreshExpiry: time.Duration(refreshExpiryDays) * 24 * time.Hour,
	}
}

func (s *JWTService) GenerateTokens(userID, email, role string, supplierID *string) (string, string, error) {
	// Generate access token
	accessToken, err := s.generateToken(userID, email, role, supplierID, s.accessExpiry, "access")
	if err != nil {
		return "", "", err
	}

	// Generate refresh token
	refreshToken, err := s.generateToken(userID, email, role, supplierID, s.refreshExpiry, "refresh")
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

func (s *JWTService) generateToken(userID, email, role string, supplierID *string, expiry time.Duration, tokenType string) (string, error) {
	now := time.Now()
	claims := &Claims{
		UserID:     userID,
		Email:      email,
		Role:       role,
		SupplierID: supplierID,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.New().String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    "scp-platform",
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.secretKey))
}

func (s *JWTService) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return []byte(s.secretKey), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

func (s *JWTService) ValidateRefreshToken(tokenString string) (*Claims, error) {
	claims, err := s.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	// Verify it's a refresh token type (you can add type claim if needed)
	return claims, nil
}

