package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
	"github.com/scp-platform/backend/internal/services"
)

type ConsumerHandler struct {
	supplierRepo *repository.SupplierRepository
	linkRepo     *repository.ConsumerLinkRepository
	productRepo  *repository.ProductRepository
	orderService *services.OrderService
	userRepo     *repository.UserRepository
}

func NewConsumerHandler(
	supplierRepo *repository.SupplierRepository,
	linkRepo *repository.ConsumerLinkRepository,
	productRepo *repository.ProductRepository,
	orderService *services.OrderService,
	userRepo *repository.UserRepository,
) *ConsumerHandler {
	return &ConsumerHandler{
		supplierRepo: supplierRepo,
		linkRepo:     linkRepo,
		productRepo:  productRepo,
		orderService: orderService,
		userRepo:     userRepo,
	}
}

func (h *ConsumerHandler) GetSuppliers(c *gin.Context) {
	page, pageSize := ParsePagination(c)
	consumerID := c.GetString("user_id")

	suppliers, total, err := h.supplierRepo.GetAll(page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Get all links for this consumer to enrich supplier data
	links, err := h.linkRepo.GetByConsumerID(consumerID)
	if err != nil {
		// If we can't get links, just return suppliers without link status
		c.JSON(http.StatusOK, PaginatedResponse(suppliers, page, pageSize, total))
		return
	}

	// Create a map of supplier ID to link status
	linkMap := make(map[string]string)
	for _, link := range links {
		linkMap[link.SupplierID] = link.Status
	}

	// Enrich suppliers with link status and add company_name alias
	type SupplierWithLinkStatus struct {
		*models.Supplier
		CompanyName string  `json:"company_name"` // Alias for name field
		LinkStatus  *string `json:"link_status,omitempty"`
		IsLinked    bool    `json:"is_linked"`
	}

	enrichedSuppliers := make([]interface{}, len(suppliers))
	for i := range suppliers {
		supplier := suppliers[i] // Create a copy to avoid pointer issues
		status, hasLink := linkMap[supplier.ID]
		supplierPtr := &supplier
		enrichedSuppliers[i] = SupplierWithLinkStatus{
			Supplier:    supplierPtr,
			CompanyName: supplier.Name, // Map name to company_name for frontend compatibility
			LinkStatus: func() *string {
				if hasLink {
					return &status
				}
				return nil
			}(),
			IsLinked: hasLink && status == "accepted",
		}
	}

	c.JSON(http.StatusOK, PaginatedResponse(enrichedSuppliers, page, pageSize, total))
}

func (h *ConsumerHandler) GetSupplier(c *gin.Context) {
	supplierID := c.Param("id")

	supplier, err := h.supplierRepo.GetByID(supplierID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Supplier not found"))
		return
	}

	// Return supplier directly as expected by Flutter frontend
	c.JSON(http.StatusOK, supplier)
}

func (h *ConsumerHandler) RequestLink(c *gin.Context) {
	supplierID := c.Param("id")
	consumerID := c.GetString("user_id")

	// Validate consumer ID exists (should always be true if authenticated, but check anyway)
	if consumerID == "" {
		c.JSON(http.StatusUnauthorized, ErrorResponse("Invalid user ID"))
		return
	}

	// Validate that the consumer exists in the database
	_, err := h.userRepo.GetByID(consumerID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ErrorResponse("Consumer not found. Please log in again."))
		return
	}

	// Validate supplier ID format (basic check)
	if supplierID == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse("Supplier ID is required"))
		return
	}

	// Check if link already exists
	_, err = h.linkRepo.GetByConsumerAndSupplier(consumerID, supplierID)
	if err == nil {
		c.JSON(http.StatusConflict, ErrorResponse("Link already exists"))
		return
	}

	// Get supplier details to include in response
	supplier, err := h.supplierRepo.GetByID(supplierID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Supplier not found"))
		return
	}

	link := &models.ConsumerLink{
		ConsumerID: consumerID,
		SupplierID: supplierID,
		Status:     "pending",
	}

	if err := h.linkRepo.Create(link); err != nil {
		// Check for specific database constraint errors
		errStr := err.Error()
		if strings.Contains(errStr, "foreign key constraint") {
			// More specific error message
			if strings.Contains(errStr, "consumer_id") {
				c.JSON(http.StatusBadRequest, ErrorResponse("Invalid consumer ID. Please log out and log in again."))
			} else if strings.Contains(errStr, "supplier_id") {
				c.JSON(http.StatusBadRequest, ErrorResponse("Invalid supplier ID. Supplier not found."))
			} else {
				c.JSON(http.StatusBadRequest, ErrorResponse("Invalid consumer or supplier ID"))
			}
			return
		}
		if strings.Contains(errStr, "unique constraint") || strings.Contains(errStr, "duplicate key") {
			// Link already exists (race condition)
			c.JSON(http.StatusConflict, ErrorResponse("Link already exists"))
			return
		}
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to create link: "+errStr))
		return
	}

	// Get the created link with ID
	createdLink, err := h.linkRepo.GetByConsumerAndSupplier(consumerID, supplierID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to retrieve created link"))
		return
	}

	// Enrich with supplier info
	createdLink.Supplier = supplier

	// Return link with supplier info as expected by Flutter frontend
	c.JSON(http.StatusCreated, createdLink)
}

func (h *ConsumerHandler) GetSupplierLinks(c *gin.Context) {
	consumerID := c.GetString("user_id")

	links, err := h.linkRepo.GetByConsumerID(consumerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Return links directly as expected by Flutter frontend
	c.JSON(http.StatusOK, links)
}

// GetLinkRequests returns link requests in paginated format for Flutter frontend
func (h *ConsumerHandler) GetLinkRequests(c *gin.Context) {
	consumerID := c.GetString("user_id")
	status := c.Query("status")

	links, err := h.linkRepo.GetByConsumerID(consumerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Filter by status if provided
	filteredLinks := []models.ConsumerLink{}
	if status != "" {
		for _, link := range links {
			if link.Status == status {
				filteredLinks = append(filteredLinks, link)
			}
		}
	} else {
		filteredLinks = links
	}

	// Transform to LinkRequest format expected by Flutter
	type LinkRequestResponse struct {
		ID            string  `json:"id"`
		SupplierID    string  `json:"supplier_id"`
		SupplierName  string  `json:"supplier_name"`
		SupplierLogoURL *string `json:"supplier_logo_url,omitempty"`
		Status        string  `json:"status"`
		Message       *string `json:"message,omitempty"`
		RequestedAt   string  `json:"requested_at"`
		RespondedAt  *string `json:"responded_at,omitempty"`
	}

	linkRequests := make([]LinkRequestResponse, len(filteredLinks))
	for i, link := range filteredLinks {
		supplierName := ""
		if link.Supplier != nil {
			supplierName = link.Supplier.Name
		}

		respondedAt := ""
		if link.ApprovedAt != nil {
			respondedAt = link.ApprovedAt.Format("2006-01-02T15:04:05.000Z")
		}

		linkRequests[i] = LinkRequestResponse{
			ID:            link.ID,
			SupplierID:    link.SupplierID,
			SupplierName:  supplierName,
			SupplierLogoURL: nil, // Not in current model
			Status:        link.Status,
			Message:       nil, // Not in current model
			RequestedAt:   link.RequestedAt.Format("2006-01-02T15:04:05.000Z"),
			RespondedAt:   func() *string {
				if respondedAt != "" {
					return &respondedAt
				}
				return nil
			}(),
		}
	}

	// Return in paginated format expected by Flutter
	c.JSON(http.StatusOK, PaginatedResponse(linkRequests, 1, len(linkRequests), len(linkRequests)))
}

func (h *ConsumerHandler) GetLinkedSuppliers(c *gin.Context) {
	consumerID := c.GetString("user_id")
	page, pageSize := ParsePagination(c)

	links, err := h.linkRepo.GetByConsumerID(consumerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Filter to only accepted links
	acceptedLinks := []interface{}{}
	for _, link := range links {
		if link.Status == "accepted" {
			// Get supplier details
			if supplier, err := h.supplierRepo.GetByID(link.SupplierID); err == nil {
				acceptedLinks = append(acceptedLinks, supplier)
			}
		}
	}

	c.JSON(http.StatusOK, PaginatedResponse(acceptedLinks, page, pageSize, len(acceptedLinks)))
}

func (h *ConsumerHandler) ApproveLink(c *gin.Context) {
	linkID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	link, err := h.linkRepo.GetByID(linkID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Link not found"))
		return
	}

	if link.SupplierID != supplierID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	if err := h.linkRepo.Approve(linkID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	link, _ = h.linkRepo.GetByID(linkID)
	// Return link directly as expected by Flutter frontend
	c.JSON(http.StatusOK, link)
}

func (h *ConsumerHandler) RejectLink(c *gin.Context) {
	linkID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	link, err := h.linkRepo.GetByID(linkID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Link not found"))
		return
	}

	if link.SupplierID != supplierID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	if err := h.linkRepo.Reject(linkID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	link, _ = h.linkRepo.GetByID(linkID)
	// Return link directly as expected by Flutter frontend
	c.JSON(http.StatusOK, link)
}

func (h *ConsumerHandler) BlockLink(c *gin.Context) {
	linkID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	link, err := h.linkRepo.GetByID(linkID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Link not found"))
		return
	}

	if link.SupplierID != supplierID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	if err := h.linkRepo.Block(linkID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	link, _ = h.linkRepo.GetByID(linkID)
	// Return link directly as expected by Flutter frontend
	c.JSON(http.StatusOK, link)
}

func (h *ConsumerHandler) GetSupplierLinksForSupplier(c *gin.Context) {
	supplierID := c.GetString("supplier_id")
	page, pageSize := ParsePagination(c)

	links, total, err := h.linkRepo.GetBySupplierID(supplierID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(links, page, pageSize, total))
}

