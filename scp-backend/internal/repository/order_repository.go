package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type OrderRepository struct {
	db *sqlx.DB
}

func NewOrderRepository(db *sqlx.DB) *OrderRepository {
	return &OrderRepository{db: db}
}

func (r *OrderRepository) GetByID(id string) (*models.Order, error) {
	var order models.Order
	// Join with suppliers and consumers to get display names
	err := r.db.Get(&order, `
		SELECT o.*,
			COALESCE(s.name, '') as supplier_name,
			u.company_name as consumer_name
		FROM orders o
		LEFT JOIN suppliers s ON o.supplier_id = s.id
		LEFT JOIN users u ON o.consumer_id = u.id
		WHERE o.id = $1
	`, id)
	if err != nil {
		return nil, err
	}

	items, err := r.getOrderItems(id)
	if err == nil {
		order.Items = items
	}

	return &order, err
}

func (r *OrderRepository) getOrderItems(orderID string) ([]models.OrderItem, error) {
	var items []models.OrderItem
	err := r.db.Select(&items, `
		SELECT oi.*, 
			p.id as "product.id",
			COALESCE(p.name, '') as "product.name",
			p.image_url as "product.image_url",
			COALESCE(p.unit, 'unit') as "product.unit"
		FROM order_items oi
		LEFT JOIN products p ON oi.product_id = p.id
		WHERE oi.order_id = $1
		ORDER BY oi.created_at
	`, orderID)
	
	// Ensure we always return a non-nil slice
	if items == nil {
		items = []models.OrderItem{}
	}
	
	return items, err
}

func (r *OrderRepository) Create(order *models.Order) error {
	tx, err := r.db.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	order.ID = uuid.New().String()
	order.CreatedAt = time.Now()
	order.Status = "pending"

	_, err = tx.NamedExec(`
		INSERT INTO orders (
			id, consumer_id, supplier_id, status,
			subtotal, tax, shipping_fee, total,
			delivery_date, delivery_start_time, delivery_end_time,
			notes, preferred_settlement,
			created_at
		)
		VALUES (
			:id, :consumer_id, :supplier_id, :status,
			:subtotal, :tax, :shipping_fee, :total,
			:delivery_date, :delivery_start_time, :delivery_end_time,
			:notes, :preferred_settlement,
			:created_at
		)
	`, order)
	if err != nil {
		return err
	}

	for _, item := range order.Items {
		item.ID = uuid.New().String()
		item.OrderID = order.ID
		item.CreatedAt = time.Now()
		_, err = tx.NamedExec(`
			INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal, created_at)
			VALUES (:id, :order_id, :product_id, :quantity, :unit_price, :subtotal, :created_at)
		`, item)
		if err != nil {
			return err
		}
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	items, _ := r.getOrderItems(order.ID)
	order.Items = items

	return nil
}

func (r *OrderRepository) GetByConsumerID(consumerID string, page, pageSize int) ([]models.Order, int, error) {
	var orders []models.Order
	var total int

	err := r.db.Get(&total, "SELECT COUNT(*) FROM orders WHERE consumer_id = $1", consumerID)
	if err != nil {
		return []models.Order{}, 0, err
	}

	offset := (page - 1) * pageSize
	// Join with suppliers and consumers to get display names
	err = r.db.Select(&orders, `
		SELECT o.*,
			COALESCE(s.name, '') as supplier_name,
			u.company_name as consumer_name
		FROM orders o
		LEFT JOIN suppliers s ON o.supplier_id = s.id
		LEFT JOIN users u ON o.consumer_id = u.id
		WHERE o.consumer_id = $1 
		ORDER BY o.created_at DESC 
		LIMIT $2 OFFSET $3
	`, consumerID, pageSize, offset)
	if err != nil {
		return []models.Order{}, 0, err
	}

	// Ensure we always return a non-nil slice
	if orders == nil {
		orders = []models.Order{}
	}

	for i := range orders {
		items, _ := r.getOrderItems(orders[i].ID)
		orders[i].Items = items
	}

	return orders, total, nil
}

func (r *OrderRepository) GetBySupplierID(supplierID string, page, pageSize int) ([]models.Order, int, error) {
	var orders []models.Order
	var total int

	err := r.db.Get(&total, "SELECT COUNT(*) FROM orders WHERE supplier_id = $1", supplierID)
	if err != nil {
		return []models.Order{}, 0, err
	}

	offset := (page - 1) * pageSize
	// Join with suppliers and consumers to get display names
	err = r.db.Select(&orders, `
		SELECT o.*,
			COALESCE(s.name, '') as supplier_name,
			u.company_name as consumer_name
		FROM orders o
		LEFT JOIN suppliers s ON o.supplier_id = s.id
		LEFT JOIN users u ON o.consumer_id = u.id
		WHERE o.supplier_id = $1 
		ORDER BY o.created_at DESC 
		LIMIT $2 OFFSET $3
	`, supplierID, pageSize, offset)
	if err != nil {
		return []models.Order{}, 0, err
	}

	// Ensure we always return a non-nil slice
	if orders == nil {
		orders = []models.Order{}
	}

	for i := range orders {
		items, _ := r.getOrderItems(orders[i].ID)
		orders[i].Items = items
	}

	return orders, total, nil
}

func (r *OrderRepository) Update(order *models.Order) error {
	now := time.Now()
	order.UpdatedAt = &now
	_, err := r.db.NamedExec(`
		UPDATE orders SET
			status = :status,
			delivery_date = :delivery_date,
			delivery_start_time = :delivery_start_time,
			delivery_end_time = :delivery_end_time,
			notes = :notes,
			preferred_settlement = :preferred_settlement,
			updated_at = :updated_at
		WHERE id = :id
	`, order)
	return err
}

