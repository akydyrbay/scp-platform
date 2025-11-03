package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type CannedReplyRepository struct {
	db *sqlx.DB
}

func NewCannedReplyRepository(db *sqlx.DB) *CannedReplyRepository {
	return &CannedReplyRepository{db: db}
}

func (r *CannedReplyRepository) GetByID(id string) (*models.CannedReply, error) {
	var reply models.CannedReply
	err := r.db.Get(&reply, "SELECT * FROM canned_replies WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &reply, nil
}

func (r *CannedReplyRepository) GetBySupplierID(supplierID string) ([]models.CannedReply, error) {
	var replies []models.CannedReply
	err := r.db.Select(&replies, `
		SELECT * FROM canned_replies 
		WHERE supplier_id = $1
		ORDER BY created_at DESC
	`, supplierID)
	return replies, err
}

func (r *CannedReplyRepository) Create(reply *models.CannedReply) error {
	reply.ID = uuid.New().String()
	reply.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO canned_replies (id, supplier_id, title, content, created_at)
		VALUES (:id, :supplier_id, :title, :content, :created_at)
	`, reply)
	return err
}

func (r *CannedReplyRepository) Update(reply *models.CannedReply) error {
	now := time.Now()
	reply.UpdatedAt = &now
	_, err := r.db.NamedExec(`
		UPDATE canned_replies SET
			title = :title,
			content = :content,
			updated_at = :updated_at
		WHERE id = :id
	`, reply)
	return err
}

func (r *CannedReplyRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM canned_replies WHERE id = $1", id)
	return err
}

