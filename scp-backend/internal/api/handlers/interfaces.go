package handlers

import (
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/services"
)

// Repository interfaces for testing
type ConversationRepositoryInterface interface {
	GetByID(id string) (*models.Conversation, error)
	GetByConsumerID(consumerID string) ([]models.Conversation, error)
	GetBySupplierID(supplierID string) ([]models.Conversation, error)
	GetOrCreate(consumerID, supplierID string) (*models.Conversation, error)
	UpdateLastMessage(conversationID string) error
}

type MessageRepositoryInterface interface {
	GetByConversationID(conversationID string, page, pageSize int) ([]models.Message, error)
	Create(message *models.Message) error
	MarkAsRead(conversationID string, userID string) error
}

type OrderRepositoryInterface interface {
	GetByConsumerID(consumerID string, page, pageSize int) ([]models.Order, int, error)
	GetBySupplierID(supplierID string, page, pageSize int) ([]models.Order, int, error)
	GetByID(orderID string) (*models.Order, error)
	Update(order *models.Order) error
}

type OrderServiceInterface interface {
	CreateOrder(consumerID string, req services.CreateOrderRequest) (*models.Order, error)
	AcceptOrder(orderID, supplierID string) error
	RejectOrder(orderID, supplierID string) error
}

