package main

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/lib/pq"
	"github.com/jmoiron/sqlx"
)

func main() {
	// Load .env file if exists
	godotenv.Load()

	// Get database config from environment
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "postgres")
	dbname := getEnv("DB_NAME", "scp_platform")
	sslmode := getEnv("DB_SSLMODE", "disable")

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		host, port, user, password, dbname, sslmode)

	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Test connection
	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	fmt.Println("✅ Connected to database")

	// Fix consumer links for chef@bistromodern.com
	consumerID := "f1111111-1111-1111-1111-111111111111"
	supplierIDs := []string{
		"11111111-1111-1111-1111-111111111111",
		"22222222-2222-2222-2222-222222222222",
		"44444444-4444-4444-4444-444444444444",
	}

	linkIDs := []string{
		"l1111111-1111-1111-1111-111111111111",
		"l1111112-1111-1111-1111-111111111111",
		"l1111113-1111-1111-1111-111111111111",
	}

	fmt.Printf("🔍 Checking consumer links for consumer ID: %s\n", consumerID)

	// First, check existing links
	var count int
	err = db.Get(&count, "SELECT COUNT(*) FROM consumer_links WHERE consumer_id = $1 AND status = 'approved'", consumerID)
	if err != nil {
		log.Fatalf("Error checking links: %v", err)
	}
	fmt.Printf("📊 Found %d approved links\n", count)

	// Update existing links to approved
	result, err := db.Exec(`
		UPDATE consumer_links 
		SET 
			status = 'approved',
			approved_at = COALESCE(approved_at, NOW() - INTERVAL '29 days'),
			requested_at = COALESCE(requested_at, NOW() - INTERVAL '30 days')
		WHERE consumer_id = $1
		AND supplier_id = ANY($2)
	`, consumerID, pq.Array(supplierIDs))
	if err != nil {
		log.Fatalf("Error updating links: %v", err)
	}
	rowsAffected, _ := result.RowsAffected()
	fmt.Printf("✅ Updated %d existing links\n", rowsAffected)

	// Insert missing links
	for i, supplierID := range supplierIDs {
		_, err := db.Exec(`
			INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at, approved_at)
			VALUES ($1, $2, $3, 'approved', NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days')
			ON CONFLICT (consumer_id, supplier_id) DO UPDATE
			SET 
				status = 'approved',
				approved_at = EXCLUDED.approved_at,
				requested_at = EXCLUDED.requested_at
		`, linkIDs[i], consumerID, supplierID)
		if err != nil {
			fmt.Printf("⚠️  Error inserting link %d: %v\n", i+1, err)
		} else {
			fmt.Printf("✅ Inserted/Updated link %d: consumer -> supplier %s\n", i+1, supplierID[:8])
		}
	}

	// Verify final count
	err = db.Get(&count, "SELECT COUNT(*) FROM consumer_links WHERE consumer_id = $1 AND status = 'approved'", consumerID)
	if err != nil {
		log.Fatalf("Error verifying links: %v", err)
	}
	fmt.Printf("\n✅ Final approved links count: %d\n", count)

	if count >= 3 {
		fmt.Println("\n🎉 SUCCESS: Consumer links fixed! Products should now be visible.")
	} else {
		fmt.Printf("\n⚠️  WARNING: Expected 3 approved links, found %d\n", count)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

