package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
)

type ComplaintHandler struct {
	complaintRepo *repository.ComplaintRepository
}

func NewComplaintHandler(complaintRepo *repository.ComplaintRepository) *ComplaintHandler {
	return &ComplaintHandler{
		complaintRepo: complaintRepo,
	}
}

func (h *ComplaintHandler) CreateComplaint(c *gin.Context) {
	supplierID := c.GetString("supplier_id")

	var req struct {
		ConversationID string  `json:"conversation_id" binding:"required"`
		ConsumerID     string  `json:"consumer_id" binding:"required"`
		OrderID        *string `json:"order_id"`
		Title          string  `json:"title" binding:"required"`
		Description    string  `json:"description" binding:"required"`
		Priority       string  `json:"priority" binding:"required,oneof=low medium high urgent"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	complaint := &models.Complaint{
		ConversationID: req.ConversationID,
		ConsumerID:     req.ConsumerID,
		SupplierID:     supplierID,
		OrderID:        req.OrderID,
		Title:          req.Title,
		Description:    req.Description,
		Priority:       req.Priority,
		Status:         "open",
	}

	if err := h.complaintRepo.Create(complaint); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusCreated, SuccessResponse(complaint))
}

func (h *ComplaintHandler) GetComplaints(c *gin.Context) {
	supplierID := c.GetString("supplier_id")
	status := c.Query("status")
	page, pageSize := ParsePagination(c)

	complaints, total, err := h.complaintRepo.GetBySupplierID(supplierID, page, pageSize, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(complaints, page, pageSize, total))
}

func (h *ComplaintHandler) EscalateComplaint(c *gin.Context) {
	complaintID := c.Param("id")
	salesRepID := c.GetString("user_id")

	complaint, err := h.complaintRepo.GetByID(complaintID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Complaint not found"))
		return
	}

	complaint.Status = "escalated"
	complaint.EscalatedBy = &salesRepID
	now := time.Now()
	complaint.EscalatedAt = &now

	if err := h.complaintRepo.Update(complaint); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(complaint))
}

func (h *ComplaintHandler) ResolveComplaint(c *gin.Context) {
	complaintID := c.Param("id")

	var req struct {
		Resolution string `json:"resolution" binding:"required,min=10"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	complaint, err := h.complaintRepo.GetByID(complaintID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Complaint not found"))
		return
	}

	complaint.Status = "resolved"
	complaint.Resolution = &req.Resolution
	now := time.Now()
	complaint.ResolvedAt = &now

	if err := h.complaintRepo.Update(complaint); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(complaint))
}

