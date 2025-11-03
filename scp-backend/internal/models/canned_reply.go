package models

import "time"

type CannedReply struct {
	ID          string     `json:"id" db:"id"`
	SupplierID  string     `json:"supplier_id" db:"supplier_id"`
	Title       string     `json:"title" db:"title"`
	Content     string     `json:"content" db:"content"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   *time.Time `json:"updated_at" db:"updated_at"`
}

