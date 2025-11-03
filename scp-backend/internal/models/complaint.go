package models

import "time"

type Complaint struct {
	ID             string     `json:"id" db:"id"`
	ConversationID string     `json:"conversation_id" db:"conversation_id"`
	ConsumerID     string     `json:"consumer_id" db:"consumer_id"`
	SupplierID     string     `json:"supplier_id" db:"supplier_id"`
	OrderID        *string    `json:"order_id" db:"order_id"`
	Title          string     `json:"title" db:"title"`
	Description    string     `json:"description" db:"description"`
	Priority       string     `json:"priority" db:"priority"`
	Status         string     `json:"status" db:"status"`
	EscalatedBy    *string    `json:"escalated_by" db:"escalated_by"`
	EscalatedAt    *time.Time `json:"escalated_at" db:"escalated_at"`
	ResolvedAt     *time.Time `json:"resolved_at" db:"resolved_at"`
	Resolution     *string    `json:"resolution" db:"resolution"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt      *time.Time `json:"updated_at" db:"updated_at"`
}

