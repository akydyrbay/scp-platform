package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type ComplaintRepository struct {
	db *sqlx.DB
}

func NewComplaintRepository(db *sqlx.DB) *ComplaintRepository {
	return &ComplaintRepository{db: db}
}

func (r *ComplaintRepository) GetByID(id string) (*models.Complaint, error) {
	var complaint models.Complaint
	err := r.db.Get(&complaint, "SELECT * FROM complaints WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &complaint, nil
}

func (r *ComplaintRepository) Create(complaint *models.Complaint) error {
	complaint.ID = uuid.New().String()
	complaint.Status = "open"
	complaint.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO complaints (id, conversation_id, consumer_id, supplier_id, order_id,
			title, description, priority, status, created_at)
		VALUES (:id, :conversation_id, :consumer_id, :supplier_id, :order_id,
			:title, :description, :priority, :status, :created_at)
	`, complaint)
	return err
}

func (r *ComplaintRepository) Update(complaint *models.Complaint) error {
	now := time.Now()
	complaint.UpdatedAt = &now
	_, err := r.db.NamedExec(`
		UPDATE complaints SET
			status = :status,
			escalated_by = :escalated_by,
			escalated_at = :escalated_at,
			resolved_at = :resolved_at,
			resolution = :resolution,
			updated_at = :updated_at
		WHERE id = :id
	`, complaint)
	return err
}

func (r *ComplaintRepository) GetBySupplierID(supplierID string, page, pageSize int, status string) ([]models.Complaint, int, error) {
	var complaints []models.Complaint
	var total int

	query := "SELECT COUNT(*) FROM complaints WHERE supplier_id = $1"
	args := []interface{}{supplierID}
	
	if status != "" {
		query += " AND status = $2"
		args = append(args, status)
	}

	err := r.db.Get(&total, query, args...)
	if err != nil {
		return nil, 0, err
	}

	selectQuery := "SELECT * FROM complaints WHERE supplier_id = $1"
	selectArgs := []interface{}{supplierID}
	
	if status != "" {
		selectQuery += " AND status = $2"
		selectArgs = append(selectArgs, status)
	}

	offset := (page - 1) * pageSize
	selectQuery += " ORDER BY created_at DESC LIMIT $2 OFFSET $3"
	if status != "" {
		selectQuery = "SELECT * FROM complaints WHERE supplier_id = $1 AND status = $2 ORDER BY created_at DESC LIMIT $3 OFFSET $4"
		args = []interface{}{supplierID, status, pageSize, offset}
	} else {
		args = []interface{}{supplierID, pageSize, offset}
	}

	err = r.db.Select(&complaints, selectQuery, args...)
	return complaints, total, err
}

