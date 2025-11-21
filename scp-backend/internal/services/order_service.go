package services

import (
	"fmt"

	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
)

type OrderService struct {
	orderRepo   *repository.OrderRepository
	productRepo *repository.ProductRepository
	linkRepo    *repository.ConsumerLinkRepository
}

func NewOrderService(orderRepo *repository.OrderRepository, productRepo *repository.ProductRepository, linkRepo *repository.ConsumerLinkRepository) *OrderService {
	return &OrderService{
		orderRepo:   orderRepo,
		productRepo: productRepo,
		linkRepo:    linkRepo,
	}
}

type CreateOrderRequest struct {
	SupplierID string
	Items      []OrderItemRequest
}

type OrderItemRequest struct {
	ProductID string
	Quantity  int
}

func (s *OrderService) CreateOrder(consumerID string, req CreateOrderRequest) (*models.Order, error) {
	// Calculate totals
	var subtotal float64
	var orderItems []models.OrderItem

	for _, itemReq := range req.Items {
		product, err := s.productRepo.GetByID(itemReq.ProductID)
		if err != nil {
			return nil, fmt.Errorf("product not found: %s", itemReq.ProductID)
		}

		if product.SupplierID != req.SupplierID {
			return nil, fmt.Errorf("product does not belong to supplier")
		}

		if product.StockLevel < itemReq.Quantity {
			return nil, fmt.Errorf("insufficient stock for product %s", product.Name)
		}

		if itemReq.Quantity < product.MinOrderQuantity {
			return nil, fmt.Errorf("quantity must be at least %d for product %s", product.MinOrderQuantity, product.Name)
		}

		price := product.Price
		if product.Discount != nil {
			price = price * (1 - *product.Discount/100)
		}

		itemSubtotal := price * float64(itemReq.Quantity)
		subtotal += itemSubtotal

		orderItems = append(orderItems, models.OrderItem{
			ProductID: product.ID,
			Quantity:  itemReq.Quantity,
			UnitPrice: price,
			Subtotal:  itemSubtotal,
		})
	}

	if subtotal <= 0 {
		return nil, fmt.Errorf("order total must be greater than 0")
	}

	tax := subtotal * 0.1 // 10% tax
	shippingFee := 0.0    // Can be calculated based on rules
	total := subtotal + tax + shippingFee

	order := &models.Order{
		ConsumerID:  consumerID,
		SupplierID:  req.SupplierID,
		Status:      "pending",
		Subtotal:    subtotal,
		Tax:         tax,
		ShippingFee: shippingFee,
		Total:       total,
		Items:       orderItems,
	}

	if err := s.orderRepo.Create(order); err != nil {
		return nil, err
	}

	return order, nil
}

func (s *OrderService) AcceptOrder(orderID string, supplierID string) error {
	order, err := s.orderRepo.GetByID(orderID)
	if err != nil {
		return fmt.Errorf("order not found")
	}

	if order.SupplierID != supplierID {
		return fmt.Errorf("unauthorized")
	}

	if order.Status != "pending" {
		return fmt.Errorf("order cannot be accepted")
	}

	// Update stock levels
	for _, item := range order.Items {
		if err := s.productRepo.DecrementStock(item.ProductID, item.Quantity); err != nil {
			return fmt.Errorf("insufficient stock for product")
		}
	}

	order.Status = "accepted"
	return s.orderRepo.Update(order)
}

func (s *OrderService) RejectOrder(orderID string, supplierID string) error {
	order, err := s.orderRepo.GetByID(orderID)
	if err != nil {
		return fmt.Errorf("order not found")
	}

	if order.SupplierID != supplierID {
		return fmt.Errorf("unauthorized")
	}

	if order.Status != "pending" {
		return fmt.Errorf("order cannot be rejected")
	}

	order.Status = "rejected"
	return s.orderRepo.Update(order)
}

