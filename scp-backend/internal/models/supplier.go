package models

import "time"

type Supplier struct {
	ID          string     `json:"id" db:"id"`
	Name        string     `json:"name" db:"name"`
	Description *string    `json:"description" db:"description"`
	Email       string     `json:"email" db:"email"`
	PhoneNumber *string    `json:"phone_number" db:"phone_number"`
	Address     *string    `json:"address" db:"address"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   *time.Time `json:"updated_at" db:"updated_at"`
}

