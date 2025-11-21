package models

import "time"

type Order struct {
	ID                  string      `json:"id" db:"id"`
	ConsumerID          string      `json:"consumer_id" db:"consumer_id"`
	SupplierID          string      `json:"supplier_id" db:"supplier_id"`
	SupplierName        string      `json:"supplier_name" db:"supplier_name"`
	ConsumerName        *string     `json:"consumer_name,omitempty" db:"consumer_name"`
	Status              string      `json:"status" db:"status"`
	Subtotal            float64     `json:"subtotal" db:"subtotal"`
	Tax                 float64     `json:"tax" db:"tax"`
	ShippingFee         float64     `json:"shipping_fee" db:"shipping_fee"`
	Total               float64     `json:"total" db:"total"`
	DeliveryDate        *time.Time  `json:"delivery_date" db:"delivery_date"`
	DeliveryStartTime   *time.Time  `json:"delivery_start_time" db:"delivery_start_time"`
	DeliveryEndTime     *time.Time  `json:"delivery_end_time" db:"delivery_end_time"`
	Notes               *string     `json:"notes" db:"notes"`
	PreferredSettlement *string     `json:"preferred_settlement" db:"preferred_settlement"`
	Items               []OrderItem `json:"items,omitempty"`
	CreatedAt           time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt           *time.Time  `json:"updated_at" db:"updated_at"`
}

type OrderItem struct {
	ID         string  `json:"id" db:"id"`
	OrderID    string  `json:"order_id" db:"order_id"`
	ProductID  string  `json:"product_id" db:"product_id"`
	Quantity   int     `json:"quantity" db:"quantity"`
	UnitPrice  float64 `json:"unit_price" db:"unit_price"`
	Subtotal   float64 `json:"subtotal" db:"subtotal"`
	Product    *Product `json:"product,omitempty"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
}

