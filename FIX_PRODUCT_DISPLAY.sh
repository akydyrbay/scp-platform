#!/bin/bash
# Fix missing consumer links to display products
# This script inserts/updates consumer links for chef@bistromodern.com

echo "🔧 Fixing consumer links for product display..."

# Try to find the API or postgres container
CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "api|postgres|scp" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "❌ No running container found. Is docker-compose running?"
    exit 1
fi

echo "📦 Found container: $CONTAINER"

# Check if it's postgres or api container
if echo "$CONTAINER" | grep -q "postgres"; then
    # Direct postgres connection
    HOST="localhost"
    echo "🔍 Using postgres container directly"
else
    # Use postgres service name (docker network)
    HOST="postgres"
    echo "🔍 Using postgres via docker network"
fi

# Run the fix SQL
SQL=$(cat <<'EOF'
-- Fix missing consumer links for chef@bistromodern.com
UPDATE consumer_links 
SET 
  status = 'approved',
  approved_at = COALESCE(approved_at, NOW() - INTERVAL '29 days'),
  requested_at = COALESCE(requested_at, NOW() - INTERVAL '30 days')
WHERE consumer_id = 'f1111111-1111-1111-1111-111111111111'
AND supplier_id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '44444444-4444-4444-4444-444444444444'
);

INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at, approved_at)
VALUES
  ('l1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'approved', NOW() - INTERVAL '30 days', NOW() - INTERVAL '29 days'),
  ('l1111112-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'approved', NOW() - INTERVAL '25 days', NOW() - INTERVAL '24 days'),
  ('l1111113-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'approved', NOW() - INTERVAL '20 days', NOW() - INTERVAL '19 days')
ON CONFLICT (consumer_id, supplier_id) DO UPDATE
SET 
  status = 'approved',
  approved_at = EXCLUDED.approved_at,
  requested_at = EXCLUDED.requested_at;

-- Verify
SELECT 
  COUNT(*) as approved_links
FROM consumer_links 
WHERE consumer_id = 'f1111111-1111-1111-1111-111111111111'
AND status = 'approved';
EOF
)

if echo "$CONTAINER" | grep -q "postgres"; then
    echo "$SQL" | docker exec -i "$CONTAINER" psql -U postgres -d scp_platform
else
    echo "$SQL" | docker exec -i "$CONTAINER" psql -h "$HOST" -U postgres -d scp_platform
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Consumer links fixed successfully!"
    echo "🔄 Restart the consumer app or refresh to see products."
else
    echo "❌ Failed to fix consumer links. Check docker logs."
    exit 1
fi

