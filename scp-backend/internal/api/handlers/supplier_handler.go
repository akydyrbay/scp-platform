package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/repository"
)

// SupplierHandler exposes supplier-specific profile/settings endpoints.
type SupplierHandler struct {
	supplierRepo *repository.SupplierRepository
}

func NewSupplierHandler(supplierRepo *repository.SupplierRepository) *SupplierHandler {
	return &SupplierHandler{
		supplierRepo: supplierRepo,
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


