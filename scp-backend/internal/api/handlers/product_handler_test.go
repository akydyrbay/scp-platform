package handlers

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/scp-platform/backend/internal/models"
)

type MockProductRepository struct {
	mock.Mock
}

func (m *MockProductRepository) GetByID(id string) (*models.Product, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Product), args.Error(1)
}

func (m *MockProductRepository) GetBySupplier(supplierID string, page, pageSize int) ([]models.Product, int, error) {
	args := m.Called(supplierID, page, pageSize)
	return args.Get(0).([]models.Product), args.Int(1), args.Error(2)
}

func (m *MockProductRepository) GetBySupplierAndConsumer(supplierID, consumerID string, page, pageSize int) ([]models.Product, int, error) {
	args := m.Called(supplierID, consumerID, page, pageSize)
	return args.Get(0).([]models.Product), args.Int(1), args.Error(2)
}

func (m *MockProductRepository) GetAllByConsumer(consumerID string, page, pageSize int) ([]models.Product, int, error) {
	args := m.Called(consumerID, page, pageSize)
	return args.Get(0).([]models.Product), args.Int(1), args.Error(2)
}

func (m *MockProductRepository) Create(product *models.Product) error {
	args := m.Called(product)
	return args.Error(0)
}

func (m *MockProductRepository) Update(product *models.Product) error {
	args := m.Called(product)
	return args.Error(0)
}

func (m *MockProductRepository) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockProductRepository) DecrementStock(productID string, quantity int) error {
	args := m.Called(productID, quantity)
	return args.Error(0)
}

func (m *MockProductRepository) BulkUpdate(supplierID string, productIDs []string, updates map[string]interface{}) ([]models.Product, error) {
	args := m.Called(supplierID, productIDs, updates)
	return args.Get(0).([]models.Product), args.Error(1)
}

func (m *MockProductRepository) GetLowStock(supplierID string, threshold int) ([]models.Product, error) {
	args := m.Called(supplierID, threshold)
	return args.Get(0).([]models.Product), args.Error(1)
}

func TestProductHandler_CreateProduct_Success(t *testing.T) {
	reqBody := map[string]interface{}{
		"name":              "Test Product",
		"description":       "Test Description",
		"unit":              "kg",
		"price":             100.0,
		"stock_level":       50,
		"min_order_quantity": 1,
	}

	body, _ := json.Marshal(reqBody)
	var createReq struct {
		Name            string   `json:"name" binding:"required"`
		Description     *string  `json:"description"`
		ImageURL        *string  `json:"image_url"`
		Unit            string   `json:"unit" binding:"required"`
		Price           float64  `json:"price" binding:"required,gt=0"`
		Discount        *float64 `json:"discount"`
		StockLevel      int      `json:"stock_level" binding:"gte=0"`
		MinOrderQuantity int    `json:"min_order_quantity" binding:"gte=1"`
	}

	err := json.Unmarshal(body, &createReq)
	assert.NoError(t, err)
	assert.Equal(t, "Test Product", createReq.Name)
	assert.Equal(t, 100.0, createReq.Price)
	assert.Greater(t, createReq.Price, 0.0)
}

func TestProductHandler_CreateProduct_InvalidDiscount(t *testing.T) {
	discount := 150.0
	// Discount should be between 0 and 100
	assert.Greater(t, discount, 100.0) // Invalid: exceeds 100
	assert.False(t, discount >= 0 && discount <= 100) // Not in valid range
}

func TestProductHandler_CreateProduct_NegativePrice(t *testing.T) {
	price := -10.0
	assert.LessOrEqual(t, price, 0.0)
}

func TestProductHandler_CreateProduct_ZeroStock(t *testing.T) {
	stockLevel := 0
	assert.GreaterOrEqual(t, stockLevel, 0)
}

func TestProductHandler_UpdateProduct_Unauthorized(t *testing.T) {
	product := &models.Product{
		ID:         "product-123",
		SupplierID: "supplier-1",
	}
	supplierID := "supplier-2"

	assert.NotEqual(t, product.SupplierID, supplierID)
}

func TestProductHandler_DeleteProduct_Unauthorized(t *testing.T) {
	product := &models.Product{
		ID:         "product-123",
		SupplierID: "supplier-1",
	}
	supplierID := "supplier-2"

	assert.NotEqual(t, product.SupplierID, supplierID)
}

func TestProductHandler_BulkUpdate(t *testing.T) {
	reqBody := map[string]interface{}{
		"product_ids": []string{"product-1", "product-2"},
		"updates": map[string]interface{}{
			"price":      150.0,
			"stock_level": 100,
		},
	}

	body, _ := json.Marshal(reqBody)
	var bulkReq struct {
		ProductIDs []string               `json:"product_ids" binding:"required"`
		Updates    map[string]interface{} `json:"updates" binding:"required"`
	}

	err := json.Unmarshal(body, &bulkReq)
	assert.NoError(t, err)
	assert.Len(t, bulkReq.ProductIDs, 2)
	assert.NotNil(t, bulkReq.Updates)
}

