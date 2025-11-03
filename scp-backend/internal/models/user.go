package models

import "time"

type User struct {
	ID            string     `json:"id" db:"id"`
	Email         string     `json:"email" db:"email"`
	PasswordHash  string     `json:"-" db:"password_hash"`
	FirstName     *string    `json:"first_name" db:"first_name"`
	LastName      *string    `json:"last_name" db:"last_name"`
	CompanyName   *string    `json:"company_name" db:"company_name"`
	PhoneNumber   *string    `json:"phone_number" db:"phone_number"`
	Role          string     `json:"role" db:"role"`
	ProfileImageURL *string  `json:"profile_image_url" db:"profile_image_url"`
	SupplierID    *string    `json:"supplier_id" db:"supplier_id"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt     *time.Time `json:"updated_at" db:"updated_at"`
}

