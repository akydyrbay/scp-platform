package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type MessageRepository struct {
	db *sqlx.DB
}

func NewMessageRepository(db *sqlx.DB) *MessageRepository {
	return &MessageRepository{db: db}
}

func (r *MessageRepository) Create(message *models.Message) error {
	message.ID = uuid.New().String()
	message.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO messages (id, conversation_id, sender_id, sender_role, content, attachment_url, is_read, created_at)
		VALUES (:id, :conversation_id, :sender_id, :sender_role, :content, :attachment_url, :is_read, :created_at)
	`, message)
	return err
}

func (r *MessageRepository) GetByConversationID(conversationID string, page, pageSize int) ([]models.Message, error) {
	var messages []models.Message
	offset := (page - 1) * pageSize
	err := r.db.Select(&messages, `
		SELECT m.*,
			u.id as "sender.id",
			u.email as "sender.email",
			u.first_name as "sender.first_name",
			u.last_name as "sender.last_name",
			u.company_name as "sender.company_name",
			u.profile_image_url as "sender.profile_image_url",
			u.role as "sender.role"
		FROM messages m
		LEFT JOIN users u ON m.sender_id = u.id
		WHERE m.conversation_id = $1
		ORDER BY m.created_at ASC
		LIMIT $2 OFFSET $3
	`, conversationID, pageSize, offset)
	
	// Ensure we always return a non-nil slice
	if messages == nil {
		messages = []models.Message{}
	}
	
	return messages, err
}

func (r *MessageRepository) MarkAsRead(conversationID string, userID string) error {
	_, err := r.db.Exec(`
		UPDATE messages 
		SET is_read = true
		WHERE conversation_id = $1 AND sender_id != $2 AND is_read = false
	`, conversationID, userID)
	return err
}

