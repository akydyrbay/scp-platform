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
		return []models.Product{}, 0, err
	}

	offset := (page - 1) * pageSize
	err = r.db.Select(&products, `
		SELECT * FROM products 
		WHERE supplier_id = $1 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3
	`, supplierID, pageSize, offset)
	
	// Ensure we always return a non-nil slice
	if products == nil {
		products = []models.Product{}
	}
	
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
		return []models.Product{}, 0, err
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
	
	// Ensure we always return a non-nil slice
	if products == nil {
		products = []models.Product{}
	}
	
	return products, total, err
}

func (r *ProductRepository) GetAllByConsumer(consumerID string, page, pageSize int) ([]models.Product, int, error) {
	var products []models.Product
	var total int

	// Debug logging
	fmt.Printf("🔍 [PRODUCT_REPO] GetAllByConsumer called\n")
	fmt.Printf("🔍 [PRODUCT_REPO] Consumer ID: %s\n", consumerID)
	fmt.Printf("🔍 [PRODUCT_REPO] Page: %d, PageSize: %d\n", page, pageSize)

	// First, check if consumer has any approved links
	var linkCount int
	linkCheckQuery := `SELECT COUNT(*) FROM consumer_links WHERE consumer_id = $1 AND status = 'approved'`
	err := r.db.Get(&linkCount, linkCheckQuery, consumerID)
	if err != nil {
		fmt.Printf("❌ [PRODUCT_REPO] Error checking consumer links: %v\n", err)
		return []models.Product{}, 0, err
	}
	fmt.Printf("🔍 [PRODUCT_REPO] Consumer has %d approved supplier links\n", linkCount)

	// Get products from all approved linked suppliers for the consumer
	countQuery := `
		SELECT COUNT(*) FROM products p
		INNER JOIN consumer_links cl ON p.supplier_id = cl.supplier_id
		WHERE cl.consumer_id = $1 AND cl.status = 'approved'
	`
	err = r.db.Get(&total, countQuery, consumerID)
	if err != nil {
		fmt.Printf("❌ [PRODUCT_REPO] Error counting products: %v\n", err)
		return []models.Product{}, 0, err
	}
	fmt.Printf("🔍 [PRODUCT_REPO] Total products found: %d\n", total)

	// Debug: Check which suppliers are linked
	var linkedSuppliers []string
	supplierCheckQuery := `SELECT supplier_id FROM consumer_links WHERE consumer_id = $1 AND status = 'approved'`
	err = r.db.Select(&linkedSuppliers, supplierCheckQuery, consumerID)
	if err != nil {
		fmt.Printf("⚠️  [PRODUCT_REPO] Error getting linked suppliers: %v\n", err)
	} else {
		fmt.Printf("🔍 [PRODUCT_REPO] Linked supplier IDs: %v\n", linkedSuppliers)
		// Check products for each supplier
		for _, supplierID := range linkedSuppliers {
			var supplierProductCount int
			supplierProductQuery := `SELECT COUNT(*) FROM products WHERE supplier_id = $1`
			err2 := r.db.Get(&supplierProductCount, supplierProductQuery, supplierID)
			if err2 != nil {
				fmt.Printf("⚠️  [PRODUCT_REPO] Error counting products for supplier %s: %v\n", supplierID, err2)
			} else {
				fmt.Printf("🔍 [PRODUCT_REPO] Supplier %s has %d products\n", supplierID, supplierProductCount)
			}
		}
	}
	
	// Additional debug: Verify consumer exists in users table
	var userEmail string
	userCheckQuery := `SELECT email FROM users WHERE id = $1`
	err = r.db.Get(&userEmail, userCheckQuery, consumerID)
	if err != nil {
		fmt.Printf("❌ [PRODUCT_REPO] Consumer ID %s NOT FOUND in users table: %v\n", consumerID, err)
	} else {
		fmt.Printf("✅ [PRODUCT_REPO] Consumer ID %s belongs to email: %s\n", consumerID, userEmail)
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
	fmt.Printf("🔍 [PRODUCT_REPO] Executing query with consumer_id=%s, limit=%d, offset=%d\n", consumerID, pageSize, offset)
	err = r.db.Select(&products, selectQuery, consumerID, pageSize, offset)
	if err != nil {
		fmt.Printf("❌ [PRODUCT_REPO] Error selecting products: %v\n", err)
		return []models.Product{}, 0, err
	}
	fmt.Printf("✅ [PRODUCT_REPO] Retrieved %d products\n", len(products))
	
	// Ensure we always return a non-nil slice
	if products == nil {
		products = []models.Product{}
	}
	
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

