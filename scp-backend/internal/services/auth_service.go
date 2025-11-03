package services

import (
	"errors"
	"time"

	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
	"github.com/scp-platform/backend/pkg/jwt"
	"github.com/scp-platform/backend/pkg/password"
)

type AuthService struct {
	userRepo *repository.UserRepository
	jwt      *jwt.JWTService
}

func NewAuthService(userRepo *repository.UserRepository, jwtService *jwt.JWTService) *AuthService {
	return &AuthService{
		userRepo: userRepo,
		jwt:      jwtService,
	}
}

func (s *AuthService) Authenticate(email, password, role string) (*models.User, error) {
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	if user.Role != role {
		return nil, errors.New("invalid role")
	}

	if !password.Verify(password, user.PasswordHash) {
		return nil, errors.New("invalid credentials")
	}

	return user, nil
}

func (s *AuthService) GenerateTokens(user *models.User) (string, string, error) {
	return s.jwt.GenerateTokens(user.ID, user.Email, user.Role, user.SupplierID)
}

func (s *AuthService) ValidateToken(tokenString string) (*jwt.Claims, error) {
	return s.jwt.ValidateToken(tokenString)
}

func (s *AuthService) RefreshToken(refreshToken string) (string, error) {
	claims, err := s.jwt.ValidateRefreshToken(refreshToken)
	if err != nil {
		return "", err
	}

	user, err := s.userRepo.GetByID(claims.UserID)
	if err != nil {
		return "", errors.New("user not found")
	}

	accessToken, _, err := s.jwt.GenerateTokens(user.ID, user.Email, user.Role, user.SupplierID)
	return accessToken, err
}

