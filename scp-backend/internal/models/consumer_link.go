package models

import "time"

type ConsumerLink struct {
	ID          string     `json:"id" db:"id"`
	ConsumerID  string     `json:"consumer_id" db:"consumer_id"`
	SupplierID string     `json:"supplier_id" db:"supplier_id"`
	Status      string     `json:"status" db:"status"`
	RequestedAt time.Time  `json:"requested_at" db:"requested_at"`
	ApprovedAt  *time.Time `json:"approved_at" db:"approved_at"`
	BlockedAt   *time.Time `json:"blocked_at" db:"blocked_at"`
	Consumer    *User      `json:"consumer,omitempty"`
	Supplier    *Supplier  `json:"supplier,omitempty"`
}

