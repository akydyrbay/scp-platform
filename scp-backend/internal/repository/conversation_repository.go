package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type ConversationRepository struct {
	db *sqlx.DB
}

func NewConversationRepository(db *sqlx.DB) *ConversationRepository {
	return &ConversationRepository{db: db}
}

func (r *ConversationRepository) GetByID(id string) (*models.Conversation, error) {
	var conv models.Conversation
	err := r.db.Get(&conv, "SELECT * FROM conversations WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &conv, nil
}

func (r *ConversationRepository) GetOrCreate(consumerID, supplierID string) (*models.Conversation, error) {
	var conv models.Conversation
	err := r.db.Get(&conv, `
		SELECT * FROM conversations 
		WHERE consumer_id = $1 AND supplier_id = $2
	`, consumerID, supplierID)

	if err == nil {
		return &conv, nil
	}

	// Create if doesn't exist
	conv.ID = uuid.New().String()
	conv.ConsumerID = consumerID
	conv.SupplierID = supplierID
	conv.UnreadCount = 0
	conv.CreatedAt = time.Now()

	_, err = r.db.NamedExec(`
		INSERT INTO conversations (id, consumer_id, supplier_id, unread_count, created_at)
		VALUES (:id, :consumer_id, :supplier_id, :unread_count, :created_at)
		ON CONFLICT (consumer_id, supplier_id) DO NOTHING
	`, conv)

	if err != nil {
		return nil, err
	}

	// Retry getting it
	err = r.db.Get(&conv, `
		SELECT * FROM conversations 
		WHERE consumer_id = $1 AND supplier_id = $2
	`, consumerID, supplierID)

	return &conv, err
}

func (r *ConversationRepository) GetByConsumerID(consumerID string) ([]models.Conversation, error) {
	var convs []models.Conversation
	err := r.db.Select(&convs, `
		SELECT c.*,
			s.id as "supplier.id",
			s.name as "supplier.name"
		FROM conversations c
		LEFT JOIN suppliers s ON c.supplier_id = s.id
		WHERE c.consumer_id = $1
		ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
	`, consumerID)
	return convs, err
}

func (r *ConversationRepository) GetBySupplierID(supplierID string) ([]models.Conversation, error) {
	var convs []models.Conversation
	err := r.db.Select(&convs, `
		SELECT c.*,
			u.id as "consumer.id",
			u.email as "consumer.email",
			u.company_name as "consumer.company_name"
		FROM conversations c
		LEFT JOIN users u ON c.consumer_id = u.id
		WHERE c.supplier_id = $1
		ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
	`, supplierID)
	return convs, err
}

func (r *ConversationRepository) UpdateLastMessage(conversationID string) error {
	_, err := r.db.Exec(`
		UPDATE conversations 
		SET last_message_at = NOW(), updated_at = NOW()
		WHERE id = $1
	`, conversationID)
	return err
}

func (r *ConversationRepository) IncrementUnreadCount(conversationID string, senderRole string) error {
	if senderRole == "consumer" {
		// Increment unread for supplier
		_, err := r.db.Exec(`
			UPDATE conversations 
			SET unread_count = unread_count + 1
			WHERE id = $1
		`, conversationID)
		return err
	}
	// For sales_rep, we might track separately
	return nil
}

func (r *ConversationRepository) ResetUnreadCount(conversationID string, userRole string) error {
	if userRole == "consumer" {
		// Consumer reads messages, reset count
		_, err := r.db.Exec(`
			UPDATE conversations 
			SET unread_count = 0
			WHERE id = $1
		`, conversationID)
		return err
	}
	return nil
}

