package models

import "time"

type Conversation struct {
	ID           string     `json:"id" db:"id"`
	ConsumerID   string     `json:"consumer_id" db:"consumer_id"`
	SupplierID   string     `json:"supplier_id" db:"supplier_id"`
	LastMessageAt *time.Time `json:"last_message_at" db:"last_message_at"`
	UnreadCount  int        `json:"unread_count" db:"unread_count"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    *time.Time `json:"updated_at" db:"updated_at"`
	Consumer     *User      `json:"consumer,omitempty"`
	Supplier     *Supplier  `json:"supplier,omitempty"`
}

type Message struct {
	ID             string     `json:"id" db:"id"`
	ConversationID string     `json:"conversation_id" db:"conversation_id"`
	SenderID       string     `json:"sender_id" db:"sender_id"`
	SenderRole     string     `json:"sender_role" db:"sender_role"`
	Content        string     `json:"content" db:"content"`
	AttachmentURL  *string    `json:"attachment_url" db:"attachment_url"`
	IsRead         bool       `json:"is_read" db:"is_read"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
	Sender         *User      `json:"sender,omitempty"`
}

