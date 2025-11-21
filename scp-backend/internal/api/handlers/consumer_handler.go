package handlers

import (
	"net/http"

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
}

func NewConsumerHandler(
	supplierRepo *repository.SupplierRepository,
	linkRepo *repository.ConsumerLinkRepository,
	productRepo *repository.ProductRepository,
	orderService *services.OrderService,
) *ConsumerHandler {
	return &ConsumerHandler{
		supplierRepo: supplierRepo,
		linkRepo:     linkRepo,
		productRepo:  productRepo,
		orderService: orderService,
	}
}

func (h *ConsumerHandler) GetSuppliers(c *gin.Context) {
	page, pageSize := ParsePagination(c)

	suppliers, total, err := h.supplierRepo.GetAll(page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(suppliers, page, pageSize, total))
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

	link, err := h.linkRepo.GetByConsumerAndSupplier(consumerID, supplierID)
	if err == nil {
		c.JSON(http.StatusConflict, ErrorResponse("Link already exists"))
		return
	}

	link = &models.ConsumerLink{
		ConsumerID: consumerID,
		SupplierID: supplierID,
		Status:     "pending",
	}

	if err := h.linkRepo.Create(link); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Return link directly as expected by Flutter frontend
	c.JSON(http.StatusCreated, link)
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

