#!/bin/bash

# Script to run database migrations
# Usage: ./scripts/run-migrations.sh

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-scp_platform}"

echo "Running migrations for database: $DB_NAME"

for migration in migrations/*.sql; do
    if [ -f "$migration" ]; then
        echo "Running: $migration"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$migration"
        if [ $? -ne 0 ]; then
            echo "Error running migration: $migration"
            exit 1
        fi
    fi
done

echo "All migrations completed successfully!"

