package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type SupplierRepository struct {
	db *sqlx.DB
}

func NewSupplierRepository(db *sqlx.DB) *SupplierRepository {
	return &SupplierRepository{db: db}
}

func (r *SupplierRepository) GetByID(id string) (*models.Supplier, error) {
	var supplier models.Supplier
	err := r.db.Get(&supplier, "SELECT * FROM suppliers WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &supplier, nil
}

func (r *SupplierRepository) Create(supplier *models.Supplier) error {
	supplier.ID = uuid.New().String()
	supplier.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO suppliers (id, name, description, email, phone_number, address, created_at)
		VALUES (:id, :name, :description, :email, :phone_number, :address, :created_at)
	`, supplier)
	return err
}

func (r *SupplierRepository) GetAll(page, pageSize int) ([]models.Supplier, int, error) {
	var suppliers []models.Supplier
	var total int

	err := r.db.Get(&total, "SELECT COUNT(*) FROM suppliers")
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err = r.db.Select(&suppliers, `
		SELECT * FROM suppliers 
		ORDER BY created_at DESC 
		LIMIT $1 OFFSET $2
	`, pageSize, offset)
	return suppliers, total, err
}

