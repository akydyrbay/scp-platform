package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type ConsumerLinkRepository struct {
	db *sqlx.DB
}

func NewConsumerLinkRepository(db *sqlx.DB) *ConsumerLinkRepository {
	return &ConsumerLinkRepository{db: db}
}

func (r *ConsumerLinkRepository) GetByID(id string) (*models.ConsumerLink, error) {
	var link models.ConsumerLink
	err := r.db.Get(&link, "SELECT * FROM consumer_links WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &link, nil
}

func (r *ConsumerLinkRepository) GetByConsumerAndSupplier(consumerID, supplierID string) (*models.ConsumerLink, error) {
	var link models.ConsumerLink
	err := r.db.Get(&link, `
		SELECT * FROM consumer_links 
		WHERE consumer_id = $1 AND supplier_id = $2
	`, consumerID, supplierID)
	if err != nil {
		return nil, err
	}
	return &link, nil
}

func (r *ConsumerLinkRepository) Create(link *models.ConsumerLink) error {
	link.ID = uuid.New().String()
	link.Status = "pending"
	link.RequestedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at)
		VALUES (:id, :consumer_id, :supplier_id, :status, :requested_at)
		ON CONFLICT (consumer_id, supplier_id) DO NOTHING
	`, link)
	return err
}

func (r *ConsumerLinkRepository) Update(link *models.ConsumerLink) error {
	_, err := r.db.NamedExec(`
		UPDATE consumer_links SET
			status = :status,
			approved_at = :approved_at,
			blocked_at = :blocked_at
		WHERE id = :id
	`, link)
	return err
}

func (r *ConsumerLinkRepository) GetByConsumerID(consumerID string) ([]models.ConsumerLink, error) {
	var links []models.ConsumerLink
	err := r.db.Select(&links, `
		SELECT cl.*, 
			s.id as "supplier.id",
			s.name as "supplier.name",
			s.description as "supplier.description"
		FROM consumer_links cl
		LEFT JOIN suppliers s ON cl.supplier_id = s.id
		WHERE cl.consumer_id = $1
		ORDER BY cl.requested_at DESC
	`, consumerID)
	return links, err
}

func (r *ConsumerLinkRepository) GetBySupplierID(supplierID string, page, pageSize int) ([]models.ConsumerLink, int, error) {
	var links []models.ConsumerLink
	var total int

	err := r.db.Get(&total, "SELECT COUNT(*) FROM consumer_links WHERE supplier_id = $1", supplierID)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err = r.db.Select(&links, `
		SELECT cl.*, 
			u.id as "consumer.id",
			u.email as "consumer.email",
			u.company_name as "consumer.company_name"
		FROM consumer_links cl
		LEFT JOIN users u ON cl.consumer_id = u.id
		WHERE cl.supplier_id = $1
		ORDER BY cl.requested_at DESC
		LIMIT $2 OFFSET $3
	`, supplierID, pageSize, offset)
	return links, total, err
}

func (r *ConsumerLinkRepository) Approve(id string) error {
	now := time.Now()
	_, err := r.db.Exec(`
		UPDATE consumer_links 
		SET status = 'approved', approved_at = $1
		WHERE id = $2
	`, now, id)
	return err
}

func (r *ConsumerLinkRepository) Reject(id string) error {
	_, err := r.db.Exec(`
		UPDATE consumer_links 
		SET status = 'rejected'
		WHERE id = $1
	`, id)
	return err
}

func (r *ConsumerLinkRepository) Block(id string) error {
	now := time.Now()
	_, err := r.db.Exec(`
		UPDATE consumer_links 
		SET status = 'blocked', blocked_at = $1
		WHERE id = $2
	`, now, id)
	return err
}

