package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type NotificationRepository struct {
	db *sqlx.DB
}

func NewNotificationRepository(db *sqlx.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

func (r *NotificationRepository) Create(notification *models.Notification) error {
	notification.ID = uuid.New().String()
	notification.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO notifications (id, user_id, type, title, message, data, is_read, created_at)
		VALUES (:id, :user_id, :type, :title, :message, :data, :is_read, :created_at)
	`, notification)
	return err
}

func (r *NotificationRepository) GetByUserID(userID string, page, pageSize int) ([]models.Notification, int, error) {
	var notifications []models.Notification
	var total int

	err := r.db.Get(&total, "SELECT COUNT(*) FROM notifications WHERE user_id = $1", userID)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	err = r.db.Select(&notifications, `
		SELECT * FROM notifications 
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, pageSize, offset)
	return notifications, total, err
}

func (r *NotificationRepository) MarkAsRead(id string) error {
	now := time.Now()
	_, err := r.db.Exec(`
		UPDATE notifications 
		SET is_read = true, read_at = $1
		WHERE id = $2
	`, now, id)
	return err
}

func (r *NotificationRepository) MarkAllAsRead(userID string) error {
	now := time.Now()
	_, err := r.db.Exec(`
		UPDATE notifications 
		SET is_read = true, read_at = $1
		WHERE user_id = $2 AND is_read = false
	`, now, userID)
	return err
}

