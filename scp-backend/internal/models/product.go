package models

import "time"

type Product struct {
	ID               string     `json:"id" db:"id"`
	Name             string     `json:"name" db:"name"`
	Description      *string    `json:"description" db:"description"`
	ImageURL         *string    `json:"image_url" db:"image_url"`
	Unit             string     `json:"unit" db:"unit"`
	Price            float64    `json:"price" db:"price"`
	Discount         *float64   `json:"discount" db:"discount"`
	StockLevel       int        `json:"stock_level" db:"stock_level"`
	MinOrderQuantity int        `json:"min_order_quantity" db:"min_order_quantity"`
	SupplierID       string     `json:"supplier_id" db:"supplier_id"`
	SupplierName     *string    `json:"supplier_name,omitempty" db:"supplier_name"`
	Category         *string    `json:"category,omitempty" db:"category"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        *time.Time `json:"updated_at" db:"updated_at"`
}

