# #!/bin/bash

# # Script to run database migrations
# # Usage: ./scripts/run-migrations.sh

# DB_HOST="${DB_HOST:-localhost}"
# DB_PORT="${DB_PORT:-5432}"
# DB_USER="${DB_USER:-postgres}"
# DB_NAME="${DB_NAME:-scp_platform}"

# echo "Running migrations for database: $DB_NAME"

# for migration in migrations/*.sql; do
#     if [ -f "$migration" ]; then
#         echo "Running: $migration"
#         PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$migration"
#         if [ $? -ne 0 ]; then
#             echo "Error running migration: $migration"
#             exit 1
#         fi
#     fi
# done

# echo "All migrations completed successfully!"

#!/bin/sh
set -eu

# Robust migration runner for the postgres container
# Usage: the container should set POSTGRES_USER, POSTGRES_DB and POSTGRES_PASSWORD

echo "Starting migration runner..."

# Wait a short while for postgres to accept connections (compose depends_on ensures it's healthy, but be defensive)
RETRIES=10
DELAY=1
count=0
until psql -h "${POSTGRES_HOST:-postgres}" -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-scp_platform}" -c '\q' >/dev/null 2>&1; do
  count=$((count+1))
  if [ "$count" -ge "$RETRIES" ]; then
    echo "Postgres is not accepting connections after $RETRIES attempts" >&2
    exit 1
  fi
  echo "Waiting for Postgres... (attempt: $count)";
  sleep $DELAY;
done

# Collect SQL files
set -- /migrations/*.sql
if [ "$#" -eq 1 ] && [ "$1" = "/migrations/*.sql" ]; then
  echo "No migration files found in /migrations";
  exit 0;
fi

for f in "$@"; do
  echo "Running migration: $f";
  psql -h "${POSTGRES_HOST:-postgres}" -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-scp_platform}" -f "$f";
done

echo "All migrations executed successfully."
