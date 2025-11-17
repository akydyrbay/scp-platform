package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/services"
)

// Mock services and repositories
type MockOrderService struct {
	mock.Mock
}

func (m *MockOrderService) CreateOrder(consumerID string, req services.CreateOrderRequest) (*models.Order, error) {
	args := m.Called(consumerID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Order), args.Error(1)
}

func (m *MockOrderService) AcceptOrder(orderID, supplierID string) error {
	args := m.Called(orderID, supplierID)
	return args.Error(0)
}

func (m *MockOrderService) RejectOrder(orderID, supplierID string) error {
	args := m.Called(orderID, supplierID)
	return args.Error(0)
}

type MockOrderRepository struct {
	mock.Mock
}

func (m *MockOrderRepository) GetByConsumerID(consumerID string, page, pageSize int) ([]models.Order, int, error) {
	args := m.Called(consumerID, page, pageSize)
	return args.Get(0).([]models.Order), args.Int(1), args.Error(2)
}

func (m *MockOrderRepository) GetBySupplierID(supplierID string, page, pageSize int) ([]models.Order, int, error) {
	args := m.Called(supplierID, page, pageSize)
	return args.Get(0).([]models.Order), args.Int(1), args.Error(2)
}

func (m *MockOrderRepository) GetByID(orderID string) (*models.Order, error) {
	args := m.Called(orderID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Order), args.Error(1)
}

func (m *MockOrderRepository) Update(order *models.Order) error {
	args := m.Called(order)
	return args.Error(0)
}

func TestOrderHandler_GetOrders(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockOrderService := new(MockOrderService)
	mockOrderRepo := new(MockOrderRepository)

	mockOrders := []models.Order{
		{ID: "order1", ConsumerID: "consumer1", Status: "pending"},
	}

	mockOrderRepo.On("GetByConsumerID", "consumer1", 1, 20).Return(mockOrders, 1, nil)

	handler := NewOrderHandler(mockOrderService, mockOrderRepo)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", "consumer1")
	c.Request = httptest.NewRequest("GET", "/consumer/orders?page=1&page_size=20", nil)

	handler.GetOrders(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotNil(t, response["results"])

	mockOrderRepo.AssertExpectations(t)
}

func TestOrderHandler_GetCurrentOrders(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockOrderService := new(MockOrderService)
	mockOrderRepo := new(MockOrderRepository)

	mockOrders := []models.Order{
		{ID: "order1", ConsumerID: "consumer1", Status: "pending"},
		{ID: "order2", ConsumerID: "consumer1", Status: "accepted"},
		{ID: "order3", ConsumerID: "consumer1", Status: "delivered"},
	}

	mockOrderRepo.On("GetByConsumerID", "consumer1", 1, 20).Return(mockOrders, 3, nil)

	handler := NewOrderHandler(mockOrderService, mockOrderRepo)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", "consumer1")
	c.Request = httptest.NewRequest("GET", "/consumer/orders/current?page=1&page_size=20", nil)

	handler.GetCurrentOrders(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotNil(t, response["results"])

	// Verify only pending/accepted orders are returned
	results := response["results"].([]interface{})
	assert.LessOrEqual(t, len(results), 2) // Should filter out delivered

	mockOrderRepo.AssertExpectations(t)
}

func TestOrderHandler_CreateOrder(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockOrderService := new(MockOrderService)
	mockOrderRepo := new(MockOrderRepository)

	orderReq := services.CreateOrderRequest{
		SupplierID: "supplier1",
		Items: []services.OrderItemRequest{
			{ProductID: "prod1", Quantity: 2},
		},
	}

	mockOrder := &models.Order{
		ID:         "order1",
		ConsumerID: "consumer1",
		SupplierID: "supplier1",
		Status:     "pending",
	}

	mockOrderService.On("CreateOrder", "consumer1", orderReq).Return(mockOrder, nil)

	handler := NewOrderHandler(mockOrderService, mockOrderRepo)

	reqBody, _ := json.Marshal(map[string]interface{}{
		"supplier_id": "supplier1",
		"items": []map[string]interface{}{
			{"product_id": "prod1", "quantity": 2},
		},
	})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", "consumer1")
	c.Request = httptest.NewRequest("POST", "/consumer/orders", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	handler.CreateOrder(c)

	assert.Equal(t, http.StatusCreated, w.Code)

	var response models.Order
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "order1", response.ID)

	mockOrderService.AssertExpectations(t)
}

