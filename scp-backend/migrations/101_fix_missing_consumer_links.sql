-- Fix missing consumer links for chef@bistromodern.com
-- This ensures the consumer has approved supplier links

-- Update existing links to approved status (if they exist)
UPDATE consumer_links 
SET 
  status = 'approved',
  approved_at = COALESCE(approved_at, now() - INTERVAL '29 days'),
  requested_at = COALESCE(requested_at, now() - INTERVAL '30 days')
WHERE consumer_id = 'f1111111-1111-1111-1111-111111111111'
AND supplier_id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '44444444-4444-4444-4444-444444444444'
);

-- Insert consumer links if they don't exist (using consumer_id + supplier_id unique constraint)
-- Fixed: Changed 'l' prefix to 'b' (valid hex) for consumer link IDs
INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at, approved_at)
VALUES
  ('b1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'approved', now() - INTERVAL '30 days', now() - INTERVAL '29 days'),
  ('b1111112-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'approved', now() - INTERVAL '25 days', now() - INTERVAL '24 days'),
  ('b1111113-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'approved', now() - INTERVAL '20 days', now() - INTERVAL '19 days')
ON CONFLICT (consumer_id, supplier_id) DO UPDATE
SET 
  status = 'approved',
  approved_at = EXCLUDED.approved_at,
  requested_at = EXCLUDED.requested_at;

