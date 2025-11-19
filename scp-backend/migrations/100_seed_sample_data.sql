-- Seed sample data for development/testing
-- This file inserts representative rows for each table created by earlier migrations.
-- It uses fixed UUIDs so foreign key references are explicit.
-- NOTE: This migration creates the pgcrypto extension to generate bcrypt hashes for passwords.

-- Enable pgcrypto for crypt() and gen_salt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Suppliers
INSERT INTO suppliers (id, name, description, email, phone_number, address, created_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Demo Supplier', 'A demo supplier for local development', 'supplier@example.com', '+10000000000', '123 Demo Street', now())
ON CONFLICT (id) DO NOTHING;

-- Users (owner, manager, consumer, sales_rep)
INSERT INTO users (id, email, password_hash, first_name, last_name, role, supplier_id, created_at)
VALUES
  ('22222222-2222-2222-2222-222222222222', 'owner@example.com', crypt('password123', gen_salt('bf', 10)), 'Owner', 'Demo', 'owner', '11111111-1111-1111-1111-111111111111', now()),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'manager@example.com', crypt('password123', gen_salt('bf', 10)), 'Manager', 'Demo', 'manager', '11111111-1111-1111-1111-111111111111', now()),
  ('33333333-3333-3333-3333-333333333333', 'consumer@example.com', crypt('password123', gen_salt('bf', 10)), 'Consumer', 'Demo', 'consumer', NULL, now()),
  ('44444444-4444-4444-4444-444444444444', 'sales@example.com', crypt('password123', gen_salt('bf', 10)), 'Sales', 'Rep', 'sales_rep', '11111111-1111-1111-1111-111111111111', now())
ON CONFLICT (email) DO NOTHING;

-- Products
INSERT INTO products (id, name, description, image_url, unit, price, discount, stock_level, min_order_quantity, supplier_id, created_at)
VALUES
  ('55555555-5555-5555-5555-555555555555', 'Demo Product A', 'Example product A', NULL, 'piece', 9.99, 0.00, 100, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('66666666-6666-6666-6666-666666666666', 'Demo Product B', 'Example product B', NULL, 'kg', 5.50, 0.00, 50, 1, '11111111-1111-1111-1111-111111111111', now())
ON CONFLICT (id) DO NOTHING;

-- Consumer links (consumer linked to supplier)
INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at, approved_at)
VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'approved', now(), now())
ON CONFLICT (consumer_id, supplier_id) DO NOTHING;

-- Conversations
INSERT INTO conversations (id, consumer_id, supplier_id, last_message_at, unread_count, created_at)
VALUES
  ('99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', now(), 0, now())
ON CONFLICT (consumer_id, supplier_id) DO NOTHING;

-- Messages
INSERT INTO messages (id, conversation_id, sender_id, sender_role, content, is_read, created_at)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', 'consumer', 'Hello, I would like to place an order.', false, now()),
  ('bbbbbbbb-aaaa-aaaa-aaaa-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999', '44444444-4444-4444-4444-444444444444', 'sales_rep', 'Thanks — please send details.', false, now())
ON CONFLICT (id) DO NOTHING;

-- Orders
INSERT INTO orders (id, consumer_id, supplier_id, status, subtotal, tax, shipping_fee, total, created_at)
VALUES
  ('77777777-7777-7777-7777-777777777777', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'pending', 25.48, 1.27, 2.50, 29.25, now())
ON CONFLICT (id) DO NOTHING;

-- Order items
INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal, created_at)
VALUES
  ('88888888-8888-8888-8888-888888888888', '77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555', 2, 9.99, 19.98, now()),
  ('99999998-8888-8888-8888-888888888889', '77777777-7777-7777-7777-777777777777', '66666666-6666-6666-6666-666666666666', 1, 5.50, 5.50, now())
ON CONFLICT (id) DO NOTHING;

-- Complaints
INSERT INTO complaints (id, conversation_id, consumer_id, supplier_id, order_id, title, description, priority, status, created_at)
VALUES
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777777', 'Damaged item', 'One of the items arrived damaged.', 'medium', 'open', now())
ON CONFLICT (id) DO NOTHING;

-- Notifications
INSERT INTO notifications (id, user_id, type, title, message, data, is_read, created_at)
VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', 'order', 'New order received', 'You have received a new order #77777777', jsonb_build_object('order_id', '77777777-7777-7777-7777-777777777777'), false, now())
ON CONFLICT (id) DO NOTHING;

-- Canned replies
INSERT INTO canned_replies (id, supplier_id, title, content, created_at)
VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'Order received', 'Thanks — your order has been received and is being processed.', now())
ON CONFLICT (id) DO NOTHING;

-- Ensure totals in orders match order_items (simple recalculation)
UPDATE orders o
SET subtotal = sq.subtotal, total = (sq.subtotal + o.tax + o.shipping_fee)
FROM (
  SELECT order_id, COALESCE(SUM(subtotal), 0) AS subtotal
  FROM order_items
  GROUP BY order_id
) sq
WHERE o.id = sq.order_id;

-- Mark last_message_at on conversations (set to the latest message created_at per conversation)
UPDATE conversations c
SET last_message_at = sub.max_created_at
FROM (
  SELECT conversation_id, MAX(created_at) AS max_created_at
  FROM messages
  GROUP BY conversation_id
) sub
WHERE c.id = sub.conversation_id;

-- End of seed
