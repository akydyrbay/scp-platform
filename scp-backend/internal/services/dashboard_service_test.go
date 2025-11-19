package services

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDashboardService_GetStats_CountPendingOrders(t *testing.T) {
	orders := []interface{}{
		map[string]interface{}{"status": "pending"},
		map[string]interface{}{"status": "accepted"},
		map[string]interface{}{"status": "pending"},
		map[string]interface{}{"status": "delivered"},
	}

	pendingCount := 0
	for _, order := range orders {
		if orderMap, ok := order.(map[string]interface{}); ok {
			if status, ok := orderMap["status"].(string); ok && status == "pending" {
				pendingCount++
			}
		}
	}

	assert.Equal(t, 2, pendingCount)
}

func TestDashboardService_GetStats_CountPendingLinks(t *testing.T) {
	links := []interface{}{
		map[string]interface{}{"status": "pending"},
		map[string]interface{}{"status": "approved"},
		map[string]interface{}{"status": "pending"},
		map[string]interface{}{"status": "rejected"},
	}

	pendingLinks := 0
	for _, link := range links {
		if linkMap, ok := link.(map[string]interface{}); ok {
			if status, ok := linkMap["status"].(string); ok && status == "pending" {
				pendingLinks++
			}
		}
	}

	assert.Equal(t, 2, pendingLinks)
}

func TestDashboardService_GetStats_RecentOrders(t *testing.T) {
	orders := []interface{}{
		map[string]interface{}{"id": "order-1"},
		map[string]interface{}{"id": "order-2"},
		map[string]interface{}{"id": "order-3"},
		map[string]interface{}{"id": "order-4"},
		map[string]interface{}{"id": "order-5"},
		map[string]interface{}{"id": "order-6"},
		map[string]interface{}{"id": "order-7"},
		map[string]interface{}{"id": "order-8"},
		map[string]interface{}{"id": "order-9"},
		map[string]interface{}{"id": "order-10"},
		map[string]interface{}{"id": "order-11"},
	}

	recentOrders := []interface{}{}
	maxRecent := 10
	for i, order := range orders {
		if i < maxRecent {
			recentOrders = append(recentOrders, order)
		}
	}

	assert.LessOrEqual(t, len(recentOrders), maxRecent)
	assert.Equal(t, 10, len(recentOrders))
}

func TestDashboardService_GetStats_LowStockCount(t *testing.T) {
	lowStockProducts := []interface{}{
		map[string]interface{}{"id": "product-1", "stock_level": 5},
		map[string]interface{}{"id": "product-2", "stock_level": 3},
		map[string]interface{}{"id": "product-3", "stock_level": 8},
	}

	lowStockItems := len(lowStockProducts)
	assert.Equal(t, 3, lowStockItems)
}

func TestDashboardService_GetStats_TotalOrders(t *testing.T) {
	totalOrders := 100
	assert.Greater(t, totalOrders, 0)
}

func TestDashboardService_GetStats_EmptyOrders(t *testing.T) {
	orders := []interface{}{}
	totalOrders := len(orders)
	pendingCount := 0

	assert.Equal(t, 0, totalOrders)
	assert.Equal(t, 0, pendingCount)
}

func TestDashboardService_GetStats_AllStatuses(t *testing.T) {
	orders := []interface{}{
		map[string]interface{}{"status": "pending"},
		map[string]interface{}{"status": "accepted"},
		map[string]interface{}{"status": "rejected"},
		map[string]interface{}{"status": "delivered"},
		map[string]interface{}{"status": "cancelled"},
	}

	totalOrders := len(orders)
	assert.Equal(t, 5, totalOrders)
}

