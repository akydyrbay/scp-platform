package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
	"github.com/scp-platform/backend/pkg/password"
)

// SupplierHandler exposes supplier-specific profile/settings endpoints.
type SupplierHandler struct {
	supplierRepo *repository.SupplierRepository
	userRepo     *repository.UserRepository
}

func NewSupplierHandler(supplierRepo *repository.SupplierRepository, userRepo *repository.UserRepository) *SupplierHandler {
	return &SupplierHandler{
		supplierRepo: supplierRepo,
		userRepo:     userRepo,
	}
}

// GetCurrentSupplier returns the supplier associated with the authenticated user.
// It uses the supplier_id set by the AuthMiddleware from the JWT claims.
func (h *SupplierHandler) GetCurrentSupplier(c *gin.Context) {
	supplierID := c.GetString("supplier_id")
	if supplierID == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse("Supplier ID not found in token"))
		return
	}

	supplier, err := h.supplierRepo.GetByID(supplierID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Supplier not found"))
		return
	}

	c.JSON(http.StatusOK, supplier)
}

// RegisterSupplier handles supplier owner registration.
// This creates both a supplier company and the owner user account.
func (h *SupplierHandler) RegisterSupplier(c *gin.Context) {
	var req struct {
		CompanyName      string  `json:"company_name" binding:"required"`
		CompanyEmail     string  `json:"company_email" binding:"required,email"`
		Description      *string `json:"description"`
		PhoneNumber      *string `json:"phone_number"`
		Address          *string `json:"address"`
		OwnerEmail       string  `json:"owner_email" binding:"required,email"`
		Password         string  `json:"password" binding:"required,min=8"`
		OwnerFirstName   string  `json:"owner_first_name" binding:"required"`
		OwnerLastName    string  `json:"owner_last_name" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// Provide more user-friendly error messages
		if validationErr, ok := err.(*gin.Error); ok && validationErr != nil {
			c.JSON(http.StatusBadRequest, ErrorResponse("Validation error: "+err.Error()))
		} else {
			c.JSON(http.StatusBadRequest, ErrorResponse("Invalid request data: "+err.Error()))
		}
		return
	}

	// Check if owner email already exists
	_, err := h.userRepo.GetByEmail(req.OwnerEmail)
	if err == nil {
		c.JSON(http.StatusConflict, ErrorResponse("User with this email already exists"))
		return
	}

	// Check if company email already exists (supplier with this email)
	// We need to check this manually since we don't have GetByEmail on supplier
	suppliers, _, err := h.supplierRepo.GetAll(1, 1000, "")
	if err == nil {
		for _, s := range suppliers {
			if s.Email == req.CompanyEmail {
				c.JSON(http.StatusConflict, ErrorResponse("Supplier with this email already exists"))
				return
			}
		}
	}

	// Hash password
	passwordHash, err := password.Hash(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to hash password"))
		return
	}

	// Create supplier
	supplier := &models.Supplier{
		Name:        req.CompanyName,
		Email:       req.CompanyEmail,
		Description: req.Description,
		PhoneNumber: req.PhoneNumber,
		Address:     req.Address,
	}

	if err := h.supplierRepo.Create(supplier); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to create supplier: "+err.Error()))
		return
	}

	// Create owner user
	ownerFirstName := req.OwnerFirstName
	ownerLastName := req.OwnerLastName
	user := &models.User{
		Email:        req.OwnerEmail,
		PasswordHash: passwordHash,
		FirstName:    &ownerFirstName,
		LastName:     &ownerLastName,
		Role:         "owner",
		SupplierID:   &supplier.ID,
	}

	if err := h.userRepo.Create(user); err != nil {
		// If user creation fails, we should ideally rollback supplier creation
		// For now, just return error
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to create owner user: "+err.Error()))
		return
	}

	// Remove password hash from response
	user.PasswordHash = ""

	// Return success response in format expected by frontend
	c.JSON(http.StatusCreated, gin.H{
		"message": "Supplier and owner account created successfully",
		"supplier": supplier,
		"user":    user,
	})
}


