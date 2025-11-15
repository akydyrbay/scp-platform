package repository

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type ProductRepository struct {
	db *sqlx.DB
}

func NewProductRepository(db *sqlx.DB) *ProductRepository {
	return &ProductRepository{db: db}
}

func (r *ProductRepository) GetByID(id string) (*models.Product, error) {
	var product models.Product
	err := r.db.Get(&product, `
		SELECT p.*, s.name as supplier_name 
		FROM products p
		LEFT JOIN suppliers s ON p.supplier_id = s.id
		WHERE p.id = $1
	`, id)
	if err != nil {
		return nil, err
	}
	return &product, nil
}

func (r *ProductRepository) GetBySupplier(supplierID string, page, pageSize int) ([]models.Product, int, error) {
	var products []models.Product
	var total int

	err := r.db.Get(&total, "SELECT COUNT(*) FROM products WHERE supplier_id = $1", supplierID)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err = r.db.Select(&products, `
		SELECT * FROM products 
		WHERE supplier_id = $1 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3
	`, supplierID, pageSize, offset)
	return products, total, err
}

func (r *ProductRepository) GetBySupplierAndConsumer(supplierID, consumerID string, page, pageSize int) ([]models.Product, int, error) {
	var products []models.Product
	var total int

	// Verify consumer-supplier link exists and is approved
	query := `
		SELECT COUNT(*) FROM products p
		INNER JOIN consumer_links cl ON p.supplier_id = cl.supplier_id
		WHERE p.supplier_id = $1 AND cl.consumer_id = $2 AND cl.status = 'approved'
	`
	err := r.db.Get(&total, query, supplierID, consumerID)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	selectQuery := `
		SELECT p.*, s.name as supplier_name FROM products p
		INNER JOIN consumer_links cl ON p.supplier_id = cl.supplier_id
		INNER JOIN suppliers s ON p.supplier_id = s.id
		WHERE p.supplier_id = $1 AND cl.consumer_id = $2 AND cl.status = 'approved'
		ORDER BY p.created_at DESC
		LIMIT $3 OFFSET $4
	`
	err = r.db.Select(&products, selectQuery, supplierID, consumerID, pageSize, offset)
	return products, total, err
}

func (r *ProductRepository) GetAllByConsumer(consumerID string, page, pageSize int) ([]models.Product, int, error) {
	var products []models.Product
	var total int

	// Get products from all approved linked suppliers for the consumer
	countQuery := `
		SELECT COUNT(*) FROM products p
		INNER JOIN consumer_links cl ON p.supplier_id = cl.supplier_id
		WHERE cl.consumer_id = $1 AND cl.status = 'approved'
	`
	err := r.db.Get(&total, countQuery, consumerID)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	selectQuery := `
		SELECT p.*, s.name as supplier_name FROM products p
		INNER JOIN consumer_links cl ON p.supplier_id = cl.supplier_id
		INNER JOIN suppliers s ON p.supplier_id = s.id
		WHERE cl.consumer_id = $1 AND cl.status = 'approved'
		ORDER BY p.created_at DESC
		LIMIT $2 OFFSET $3
	`
	err = r.db.Select(&products, selectQuery, consumerID, pageSize, offset)
	return products, total, err
}

func (r *ProductRepository) Create(product *models.Product) error {
	product.ID = uuid.New().String()
	product.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO products (id, name, description, image_url, unit, price, discount,
			stock_level, min_order_quantity, supplier_id, created_at)
		VALUES (:id, :name, :description, :image_url, :unit, :price, :discount,
			:stock_level, :min_order_quantity, :supplier_id, :created_at)
	`, product)
	return err
}

func (r *ProductRepository) Update(product *models.Product) error {
	now := time.Now()
	product.UpdatedAt = &now
	_, err := r.db.NamedExec(`
		UPDATE products SET
			name = :name,
			description = :description,
			image_url = :image_url,
			unit = :unit,
			price = :price,
			discount = :discount,
			stock_level = :stock_level,
			min_order_quantity = :min_order_quantity,
			updated_at = :updated_at
		WHERE id = :id
	`, product)
	return err
}

func (r *ProductRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM products WHERE id = $1", id)
	return err
}

func (r *ProductRepository) DecrementStock(productID string, quantity int) error {
	result, err := r.db.Exec(`
		UPDATE products 
		SET stock_level = stock_level - $1,
			updated_at = NOW()
		WHERE id = $2 AND stock_level >= $1
	`, quantity, productID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("insufficient stock or product not found")
	}

	return nil
}

func (r *ProductRepository) BulkUpdate(supplierID string, productIDs []string, updates map[string]interface{}) ([]models.Product, error) {
	var products []models.Product

	tx, err := r.db.Beginx()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	for _, productID := range productIDs {
		var product models.Product
		err := tx.Get(&product, "SELECT * FROM products WHERE id = $1 AND supplier_id = $2", productID, supplierID)
		if err != nil {
			continue
		}

		setParts := []string{"updated_at = NOW()"}
		args := []interface{}{}
		argNum := 1

		if price, ok := updates["price"].(*float64); ok && price != nil {
			setParts = append(setParts, fmt.Sprintf("price = $%d", argNum))
			args = append(args, *price)
			argNum++
		}

		if stock, ok := updates["stock_level"].(*int); ok && stock != nil {
			setParts = append(setParts, fmt.Sprintf("stock_level = $%d", argNum))
			args = append(args, *stock)
			argNum++
		}

		if discount, ok := updates["discount"].(*float64); ok && discount != nil {
			setParts = append(setParts, fmt.Sprintf("discount = $%d", argNum))
			args = append(args, *discount)
			argNum++
		}

		if len(setParts) > 1 {
			setParts = append(setParts, fmt.Sprintf("id = $%d", argNum))
			args = append(args, productID)
			argNum++
			setParts = append(setParts, fmt.Sprintf("supplier_id = $%d", argNum))
			args = append(args, supplierID)

			query := fmt.Sprintf("UPDATE products SET %s WHERE id = $%d AND supplier_id = $%d",
				fmt.Sprint(setParts[:len(setParts)-2]), argNum, argNum+1)

			_, err = tx.Exec(query, args...)
			if err != nil {
				continue
			}

			var updatedProduct models.Product
			tx.Get(&updatedProduct, "SELECT * FROM products WHERE id = $1", productID)
			products = append(products, updatedProduct)
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return products, nil
}

func (r *ProductRepository) GetLowStock(supplierID string, threshold int) ([]models.Product, error) {
	var products []models.Product
	err := r.db.Select(&products, `
		SELECT * FROM products 
		WHERE supplier_id = $1 AND stock_level <= $2
		ORDER BY stock_level ASC
	`, supplierID, threshold)
	return products, err
}

