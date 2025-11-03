package repository

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
	"github.com/jmoiron/sqlx"
)

type Database struct {
	DB *sqlx.DB
}

func NewDatabase(host string, port int, user, password, dbname, sslmode string) (*Database, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		host, port, user, password, dbname, sslmode)

	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &Database{DB: db}, nil
}

func (d *Database) Close() error {
	return d.DB.Close()
}

