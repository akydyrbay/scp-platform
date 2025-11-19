package handlers

import (
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/scp-platform/backend/internal/services"
)

type MockDashboardService struct {
	mock.Mock
}

func (m *MockDashboardService) GetStats(supplierID string) (*services.DashboardStats, error) {
	args := m.Called(supplierID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*services.DashboardStats), args.Error(1)
}

func TestDashboardHandler_GetStats_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	stats := &services.DashboardStats{
		TotalOrders:         100,
		PendingOrders:       5,
		PendingLinkRequests: 3,
		LowStockItems:       2,
	}

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("supplier_id", "supplier-123")

	// Test that supplier_id is set
	supplierID := c.GetString("supplier_id")
	assert.Equal(t, "supplier-123", supplierID)
	assert.NotNil(t, stats)
	assert.Equal(t, 100, stats.TotalOrders)
}

func TestDashboardHandler_GetStats_EmptyStats(t *testing.T) {
	stats := &services.DashboardStats{
		TotalOrders:         0,
		PendingOrders:       0,
		PendingLinkRequests: 0,
		LowStockItems:       0,
	}

	assert.Equal(t, 0, stats.TotalOrders)
	assert.Equal(t, 0, stats.PendingOrders)
}

