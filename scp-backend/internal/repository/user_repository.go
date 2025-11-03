package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/scp-platform/backend/internal/models"
)

type UserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) GetByID(id string) (*models.User, error) {
	var user models.User
	err := r.db.Get(&user, "SELECT * FROM users WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) GetByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Get(&user, "SELECT * FROM users WHERE email = $1", email)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) Create(user *models.User) error {
	user.ID = uuid.New().String()
	user.CreatedAt = time.Now()
	_, err := r.db.NamedExec(`
		INSERT INTO users (id, email, password_hash, first_name, last_name, company_name, 
			phone_number, role, profile_image_url, supplier_id, created_at)
		VALUES (:id, :email, :password_hash, :first_name, :last_name, :company_name,
			:phone_number, :role, :profile_image_url, :supplier_id, :created_at)
	`, user)
	return err
}

func (r *UserRepository) Update(user *models.User) error {
	now := time.Now()
	user.UpdatedAt = &now
	_, err := r.db.NamedExec(`
		UPDATE users SET
			email = :email,
			first_name = :first_name,
			last_name = :last_name,
			company_name = :company_name,
			phone_number = :phone_number,
			profile_image_url = :profile_image_url,
			updated_at = :updated_at
		WHERE id = :id
	`, user)
	return err
}

func (r *UserRepository) GetBySupplierID(supplierID string) ([]models.User, error) {
	var users []models.User
	err := r.db.Select(&users, "SELECT * FROM users WHERE supplier_id = $1 ORDER BY created_at DESC", supplierID)
	return users, err
}

func (r *UserRepository) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM users WHERE id = $1", id)
	return err
}

