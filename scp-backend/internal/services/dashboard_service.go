package services

import (
	"github.com/scp-platform/backend/internal/repository"
)

type DashboardService struct {
	orderRepo   *repository.OrderRepository
	linkRepo    *repository.ConsumerLinkRepository
	productRepo *repository.ProductRepository
}

func NewDashboardService(orderRepo *repository.OrderRepository, linkRepo *repository.ConsumerLinkRepository, productRepo *repository.ProductRepository) *DashboardService {
	return &DashboardService{
		orderRepo:   orderRepo,
		linkRepo:    linkRepo,
		productRepo: productRepo,
	}
}

type DashboardStats struct {
	TotalOrders         int                   `json:"total_orders"`
	PendingOrders       int                   `json:"pending_orders"`
	PendingLinkRequests int                   `json:"pending_link_requests"`
	LowStockItems       int                   `json:"low_stock_items"`
	RecentOrders        []interface{}         `json:"recent_orders"`
	LowStockProducts    []interface{}         `json:"low_stock_products"`
}

func (s *DashboardService) GetStats(supplierID string) (*DashboardStats, error) {
	// Get all orders
	orders, totalOrders, err := s.orderRepo.GetBySupplierID(supplierID, 1, 1000)
	if err != nil {
		return nil, err
	}

	// Count pending orders
	pendingCount := 0
	recentOrders := []interface{}{}
	for i, order := range orders {
		if order.Status == "pending" {
			pendingCount++
		}
		if i < 10 {
			recentOrders = append(recentOrders, order)
		}
	}

	// Get pending link requests
	links, _, err := s.linkRepo.GetBySupplierID(supplierID, 1, 1000)
	if err != nil {
		return nil, err
	}

	pendingLinks := 0
	for _, link := range links {
		if link.Status == "pending" {
			pendingLinks++
		}
	}

	// Get low stock products
	lowStockProducts, err := s.productRepo.GetLowStock(supplierID, 10)
	if err != nil {
		return nil, err
	}

	lowStockItems := []interface{}{}
	for _, product := range lowStockProducts {
		lowStockItems = append(lowStockItems, product)
	}

	return &DashboardStats{
		TotalOrders:         totalOrders,
		PendingOrders:       pendingCount,
		PendingLinkRequests: pendingLinks,
		LowStockItems:        len(lowStockProducts),
		RecentOrders:        recentOrders,
		LowStockProducts:    lowStockItems,
	}, nil
}

