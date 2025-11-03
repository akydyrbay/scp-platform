package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/services"
)

type DashboardHandler struct {
	dashboardService *services.DashboardService
}

func NewDashboardHandler(dashboardService *services.DashboardService) *DashboardHandler {
	return &DashboardHandler{
		dashboardService: dashboardService,
	}
}

func (h *DashboardHandler) GetStats(c *gin.Context) {
	supplierID := c.GetString("supplier_id")

	stats, err := h.dashboardService.GetStats(supplierID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(stats))
}

