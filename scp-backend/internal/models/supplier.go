package models

import "time"

type Supplier struct {
	ID                string     `json:"id" db:"id"`
	Name              string     `json:"name" db:"name"`
	Description       *string    `json:"description" db:"description"`
	Email             string     `json:"email" db:"email"`
	PhoneNumber       *string    `json:"phone_number" db:"phone_number"`
	Address           *string    `json:"address" db:"address"`
	LegalEntity       *string    `json:"legal_entity" db:"legal_entity"`
	Headquarters      *string    `json:"headquarters" db:"headquarters"`
	RegisteredAddress *string    `json:"registered_address" db:"registered_address"`
	BankingCurrency   *string    `json:"banking_currency" db:"banking_currency"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt         *time.Time `json:"updated_at" db:"updated_at"`
}

