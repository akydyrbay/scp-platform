package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
	"github.com/scp-platform/backend/internal/services"
	"github.com/scp-platform/backend/pkg/password"
)

type AuthHandler struct {
	authService *services.AuthService
	userRepo    *repository.UserRepository
}

func NewAuthHandler(authService *services.AuthService, userRepo *repository.UserRepository) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		userRepo:    userRepo,
	}
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=6"`
		Role     string `json:"role" binding:"required,oneof=consumer owner manager sales_rep"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	user, err := h.authService.Authenticate(req.Email, req.Password, req.Role)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse("Invalid credentials"))
		return
	}

	accessToken, refreshToken, err := h.authService.GenerateTokens(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to generate tokens"))
		return
	}

	// Remove password hash from response
	user.PasswordHash = ""

	// Return direct format expected by Flutter frontend
	c.JSON(http.StatusOK, gin.H{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"user":          user,
	})
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	accessToken, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse("Invalid refresh token"))
		return
	}

	// Return direct format expected by Flutter frontend
	c.JSON(http.StatusOK, gin.H{
		"access_token": accessToken,
	})
}

func (h *AuthHandler) GetCurrentUser(c *gin.Context) {
	userID := c.GetString("user_id")

	user, err := h.userRepo.GetByID(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("User not found"))
		return
	}

	user.PasswordHash = ""
	// Return user directly as expected by frontend
	c.JSON(http.StatusOK, user)
}

func (h *AuthHandler) Logout(c *gin.Context) {
	// Token invalidation can be handled via Redis if needed
	c.JSON(http.StatusOK, SuccessResponse(gin.H{"message": "Logged out successfully"}))
}

func (h *AuthHandler) CreateUser(c *gin.Context) {
	var req struct {
		Email     string  `json:"email" binding:"required,email"`
		Password  string  `json:"password" binding:"required,min=8"`
		FirstName *string `json:"first_name"`
		LastName  *string `json:"last_name"`
		Role      string  `json:"role" binding:"required,oneof=consumer owner manager sales_rep"`
		SupplierID *string `json:"supplier_id"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	// Check if user exists
	_, err := h.userRepo.GetByEmail(req.Email)
	if err == nil {
		c.JSON(http.StatusConflict, ErrorResponse("User already exists"))
		return
	}

	passwordHash, err := password.Hash(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to hash password"))
		return
	}

	user := &models.User{
		Email:        req.Email,
		PasswordHash: passwordHash,
		FirstName:    req.FirstName,
		LastName:      req.LastName,
		Role:         req.Role,
		SupplierID:   req.SupplierID,
	}

	if err := h.userRepo.Create(user); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to create user"))
		return
	}

	user.PasswordHash = ""
	// Return user directly as expected by frontend
	c.JSON(http.StatusCreated, user)
}

func (h *AuthHandler) GetUsers(c *gin.Context) {
	supplierID := c.GetString("supplier_id")
	if supplierID == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse("Supplier ID required"))
		return
	}

	users, err := h.userRepo.GetBySupplierID(supplierID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Remove password hashes
	for i := range users {
		users[i].PasswordHash = ""
	}

	// Return users directly as expected by frontend
	c.JSON(http.StatusOK, users)
}

func (h *AuthHandler) DeleteUser(c *gin.Context) {
	userID := c.Param("id")
	currentUserID := c.GetString("user_id")

	if userID == currentUserID {
		c.JSON(http.StatusBadRequest, ErrorResponse("Cannot delete yourself"))
		return
	}

	if err := h.userRepo.Delete(userID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(gin.H{"message": "User deleted successfully"}))
}

func SuccessResponse(data interface{}) gin.H {
	return gin.H{
		"success": true,
		"data":    data,
	}
}

func ErrorResponse(message string) gin.H {
	return gin.H{
		"success": false,
		"error": gin.H{
			"code":    "ERROR",
			"message": message,
		},
	}
}

func PaginatedResponse(results interface{}, page, pageSize, total int) gin.H {
	totalPages := (total + pageSize - 1) / pageSize
	if totalPages == 0 {
		totalPages = 1
	}
	// Return format expected by Flutter frontend (results at top level)
	return gin.H{
		"results": results,
		"pagination": gin.H{
			"page":        page,
			"page_size":   pageSize,
			"total":       total,
			"total_pages": totalPages,
		},
	}
}

func ParsePagination(c *gin.Context) (int, int) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}

	return page, pageSize
}

