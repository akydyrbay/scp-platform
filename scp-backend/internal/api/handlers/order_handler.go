package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/repository"
	"github.com/scp-platform/backend/internal/services"
)

type OrderHandler struct {
	orderService *services.OrderService
	orderRepo    *repository.OrderRepository
}

func NewOrderHandler(orderService *services.OrderService, orderRepo *repository.OrderRepository) *OrderHandler {
	return &OrderHandler{
		orderService: orderService,
		orderRepo:    orderRepo,
	}
}

func (h *OrderHandler) CreateOrder(c *gin.Context) {
	consumerID := c.GetString("user_id")

	var req struct {
		SupplierID string `json:"supplier_id" binding:"required"`
		Items      []struct {
			ProductID string `json:"product_id" binding:"required"`
			Quantity  int    `json:"quantity" binding:"required,gt=0"`
		} `json:"items" binding:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	orderReq := services.CreateOrderRequest{
		SupplierID: req.SupplierID,
		Items:      make([]services.OrderItemRequest, len(req.Items)),
	}

	for i, item := range req.Items {
		orderReq.Items[i] = services.OrderItemRequest{
			ProductID: item.ProductID,
			Quantity:  item.Quantity,
		}
	}

	order, err := h.orderService.CreateOrder(consumerID, orderReq)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	// Return order directly as expected by Flutter frontend
	c.JSON(http.StatusCreated, order)
}

func (h *OrderHandler) GetOrders(c *gin.Context) {
	consumerID := c.GetString("user_id")
	page, pageSize := ParsePagination(c)

	orders, total, err := h.orderRepo.GetByConsumerID(consumerID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(orders, page, pageSize, total))
}

func (h *OrderHandler) GetOrder(c *gin.Context) {
	orderID := c.Param("id")
	userID := c.GetString("user_id")

	order, err := h.orderRepo.GetByID(orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Order not found"))
		return
	}

	if order.ConsumerID != userID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	// Return order directly as expected by Flutter frontend
	c.JSON(http.StatusOK, order)
}

func (h *OrderHandler) GetSupplierOrders(c *gin.Context) {
	supplierID := c.GetString("supplier_id")
	page, pageSize := ParsePagination(c)

	orders, total, err := h.orderRepo.GetBySupplierID(supplierID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(orders, page, pageSize, total))
}

func (h *OrderHandler) AcceptOrder(c *gin.Context) {
	orderID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	if err := h.orderService.AcceptOrder(orderID, supplierID); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	order, _ := h.orderRepo.GetByID(orderID)
	// Return order directly as expected by Flutter frontend
	c.JSON(http.StatusOK, order)
}

func (h *OrderHandler) RejectOrder(c *gin.Context) {
	orderID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	if err := h.orderService.RejectOrder(orderID, supplierID); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	order, _ := h.orderRepo.GetByID(orderID)
	// Return order directly as expected by Flutter frontend
	c.JSON(http.StatusOK, order)
}

func (h *OrderHandler) GetCurrentOrders(c *gin.Context) {
	consumerID := c.GetString("user_id")
	page, pageSize := ParsePagination(c)

	orders, _, err := h.orderRepo.GetByConsumerID(consumerID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Filter to only pending/accepted orders (current/active)
	currentOrders := []interface{}{}
	for _, order := range orders {
		if order.Status == "pending" || order.Status == "accepted" {
			currentOrders = append(currentOrders, order)
		}
	}

	c.JSON(http.StatusOK, PaginatedResponse(currentOrders, page, pageSize, len(currentOrders)))
}

func (h *OrderHandler) CancelOrder(c *gin.Context) {
	orderID := c.Param("id")
	consumerID := c.GetString("user_id")

	order, err := h.orderRepo.GetByID(orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Order not found"))
		return
	}

	if order.ConsumerID != consumerID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	if order.Status != "pending" {
		c.JSON(http.StatusBadRequest, ErrorResponse("Only pending orders can be cancelled"))
		return
	}

	order.Status = "cancelled"
	if err := h.orderRepo.Update(order); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Return order directly as expected by Flutter frontend
	c.JSON(http.StatusOK, order)
}

