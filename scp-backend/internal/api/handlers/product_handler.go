package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
)

type ProductHandler struct {
	productRepo *repository.ProductRepository
}

func NewProductHandler(productRepo *repository.ProductRepository) *ProductHandler {
	return &ProductHandler{
		productRepo: productRepo,
	}
}

func (h *ProductHandler) GetProducts(c *gin.Context) {
	supplierID := c.GetString("supplier_id")
	page, pageSize := ParsePagination(c)

	products, total, err := h.productRepo.GetBySupplier(supplierID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(products, page, pageSize, total))
}

func (h *ProductHandler) GetConsumerProducts(c *gin.Context) {
	consumerID := c.GetString("user_id")
	supplierID := c.Query("supplier_id")
	
	page, pageSize := ParsePagination(c)

	var products []models.Product
	var total int
	var err error

	// If supplier_id is provided, get products from that specific supplier
	// Otherwise, get products from all approved linked suppliers
	if supplierID != "" {
		products, total, err = h.productRepo.GetBySupplierAndConsumer(supplierID, consumerID, page, pageSize)
	} else {
		products, total, err = h.productRepo.GetAllByConsumer(consumerID, page, pageSize)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(products, page, pageSize, total))
}

func (h *ProductHandler) GetProduct(c *gin.Context) {
	productID := c.Param("id")

	product, err := h.productRepo.GetByID(productID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Product not found"))
		return
	}

	// Return product directly as expected by Flutter frontend
	c.JSON(http.StatusOK, product)
}

func (h *ProductHandler) CreateProduct(c *gin.Context) {
	supplierID := c.GetString("supplier_id")

	var req struct {
		Name            string   `json:"name" binding:"required"`
		Description     *string  `json:"description"`
		ImageURL        *string  `json:"image_url"`
		Unit            string   `json:"unit" binding:"required"`
		Price           float64  `json:"price" binding:"required,gt=0"`
		Discount        *float64 `json:"discount"`
		StockLevel      int      `json:"stock_level" binding:"gte=0"`
		MinOrderQuantity int     `json:"min_order_quantity" binding:"gte=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	if req.Discount != nil && (*req.Discount < 0 || *req.Discount > 100) {
		c.JSON(http.StatusBadRequest, ErrorResponse("Discount must be between 0 and 100"))
		return
	}

	product := &models.Product{
		Name:            req.Name,
		Description:     req.Description,
		ImageURL:        req.ImageURL,
		Unit:            req.Unit,
		Price:           req.Price,
		Discount:        req.Discount,
		StockLevel:      req.StockLevel,
		MinOrderQuantity: req.MinOrderQuantity,
		SupplierID:      supplierID,
	}

	if err := h.productRepo.Create(product); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Return product directly as expected by Flutter frontend
	c.JSON(http.StatusCreated, product)
}

func (h *ProductHandler) UpdateProduct(c *gin.Context) {
	productID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	product, err := h.productRepo.GetByID(productID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Product not found"))
		return
	}

	if product.SupplierID != supplierID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	var req struct {
		Name            *string  `json:"name"`
		Description     *string  `json:"description"`
		ImageURL        *string  `json:"image_url"`
		Unit            *string  `json:"unit"`
		Price           *float64 `json:"price"`
		Discount        *float64 `json:"discount"`
		StockLevel      *int     `json:"stock_level"`
		MinOrderQuantity *int    `json:"min_order_quantity"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	if req.Name != nil {
		product.Name = *req.Name
	}
	if req.Description != nil {
		product.Description = req.Description
	}
	if req.ImageURL != nil {
		product.ImageURL = req.ImageURL
	}
	if req.Unit != nil {
		product.Unit = *req.Unit
	}
	if req.Price != nil {
		product.Price = *req.Price
	}
	if req.Discount != nil {
		if *req.Discount < 0 || *req.Discount > 100 {
			c.JSON(http.StatusBadRequest, ErrorResponse("Discount must be between 0 and 100"))
			return
		}
		product.Discount = req.Discount
	}
	if req.StockLevel != nil {
		product.StockLevel = *req.StockLevel
	}
	if req.MinOrderQuantity != nil {
		product.MinOrderQuantity = *req.MinOrderQuantity
	}

	if err := h.productRepo.Update(product); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Return product directly as expected by Flutter frontend
	c.JSON(http.StatusOK, product)
}

func (h *ProductHandler) DeleteProduct(c *gin.Context) {
	productID := c.Param("id")
	supplierID := c.GetString("supplier_id")

	product, err := h.productRepo.GetByID(productID)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse("Product not found"))
		return
	}

	if product.SupplierID != supplierID {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized"))
		return
	}

	if err := h.productRepo.Delete(productID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(gin.H{"message": "Product deleted successfully"}))
}

func (h *ProductHandler) BulkUpdateProducts(c *gin.Context) {
	supplierID := c.GetString("supplier_id")

	var req struct {
		ProductIDs []string               `json:"product_ids" binding:"required"`
		Updates     map[string]interface{} `json:"updates" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	products, err := h.productRepo.BulkUpdate(supplierID, req.ProductIDs, req.Updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(products))
}

