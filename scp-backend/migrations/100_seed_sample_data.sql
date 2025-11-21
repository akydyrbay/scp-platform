-- Seed sample data for development/testing
-- This file inserts representative rows for each table created by earlier migrations.
-- It uses fixed UUIDs so foreign key references are explicit.
-- NOTE: This migration creates the pgcrypto extension to generate bcrypt hashes for passwords.

-- Enable pgcrypto for crypt() and gen_salt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Suppliers (Multiple realistic suppliers)
INSERT INTO suppliers (id, name, description, email, phone_number, address, legal_entity, headquarters, registered_address, banking_currency, created_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Fresh Farm Produce Co.', 'Premium fresh vegetables and fruits supplier for restaurants and hotels', 'contact@freshfarm.com', '+1-555-0101', '1234 Agriculture Blvd, Farm City, FC 12345', 'Fresh Farm Produce Co. LLC', 'Farm City HQ', '1234 Agriculture Blvd, Farm City, FC 12345', 'USD', now()),
  ('22222222-2222-2222-2222-222222222222', 'Ocean Fresh Seafood', 'High-quality fresh seafood and fish products', 'sales@oceanfresh.com', '+1-555-0202', '5678 Harbor Way, Coastal City, CC 23456', 'Ocean Fresh Seafood Ltd.', 'Coastal City HQ', '5678 Harbor Way, Coastal City, CC 23456', 'USD', now()),
  ('33333333-3333-3333-3333-333333333333', 'Premium Meats & Poultry', 'Premium quality beef, pork, chicken, and lamb', 'orders@premiummeats.com', '+1-555-0303', '9012 Ranch Road, Meat City, MC 34567', 'Premium Meats & Poultry LLP', 'Meat City HQ', '9012 Ranch Road, Meat City, MC 34567', 'USD', now()),
  ('44444444-4444-4444-4444-444444444444', 'Dairy Delights', 'Fresh dairy products, cheese, and specialty items', 'info@dairydelights.com', '+1-555-0404', '3456 Farm Lane, Dairy Town, DT 45678', 'Dairy Delights JSC', 'Dairy Town HQ', '3456 Farm Lane, Dairy Town, DT 45678', 'USD', now()),
  ('55555555-5555-5555-5555-555555555555', 'Beverage Solutions Inc.', 'Wide selection of beverages, juices, and soft drinks', 'sales@beveragesolutions.com', '+1-555-0505', '7890 Drink Avenue, Beverage City, BC 56789', 'Beverage Solutions Inc.', 'Beverage City HQ', '7890 Drink Avenue, Beverage City, BC 56789', 'USD', now())
ON CONFLICT (id) DO NOTHING;

-- Users (owner, manager, consumer, sales_rep)
INSERT INTO users (id, email, password_hash, first_name, last_name, company_name, phone_number, role, supplier_id, created_at)
VALUES
  -- Supplier 1 (Fresh Farm) users
  ('a1111111-1111-1111-1111-111111111111', 'owner@freshfarm.com', crypt('password123', gen_salt('bf', 10)), 'John', 'Smith', 'Fresh Farm Produce Co.', '+1-555-1001', 'owner', '11111111-1111-1111-1111-111111111111', now()),
  ('a2222222-2222-2222-2222-222222222222', 'manager@freshfarm.com', crypt('password123', gen_salt('bf', 10)), 'Sarah', 'Johnson', 'Fresh Farm Produce Co.', '+1-555-1002', 'manager', '11111111-1111-1111-1111-111111111111', now()),
  ('a3333333-3333-3333-3333-333333333333', 'sales1@freshfarm.com', crypt('password123', gen_salt('bf', 10)), 'Mike', 'Williams', 'Fresh Farm Produce Co.', '+1-555-1003', 'sales_rep', '11111111-1111-1111-1111-111111111111', now()),
  
  -- Supplier 2 (Ocean Fresh) users
  ('b1111111-1111-1111-1111-111111111111', 'owner@oceanfresh.com', crypt('password123', gen_salt('bf', 10)), 'David', 'Brown', 'Ocean Fresh Seafood', '+1-555-2001', 'owner', '22222222-2222-2222-2222-222222222222', now()),
  ('b2222222-2222-2222-2222-222222222222', 'sales1@oceanfresh.com', crypt('password123', gen_salt('bf', 10)), 'Lisa', 'Davis', 'Ocean Fresh Seafood', '+1-555-2002', 'sales_rep', '22222222-2222-2222-2222-222222222222', now()),
  
  -- Supplier 3 (Premium Meats) users
  ('c1111111-1111-1111-1111-111111111111', 'owner@premiummeats.com', crypt('password123', gen_salt('bf', 10)), 'Robert', 'Miller', 'Premium Meats & Poultry', '+1-555-3001', 'owner', '33333333-3333-3333-3333-333333333333', now()),
  ('c2222222-2222-2222-2222-222222222222', 'manager@premiummeats.com', crypt('password123', gen_salt('bf', 10)), 'Emily', 'Wilson', 'Premium Meats & Poultry', '+1-555-3002', 'manager', '33333333-3333-3333-3333-333333333333', now()),
  
  -- Supplier 4 (Dairy Delights) users
  ('d1111111-1111-1111-1111-111111111111', 'owner@dairydelights.com', crypt('password123', gen_salt('bf', 10)), 'Jennifer', 'Moore', 'Dairy Delights', '+1-555-4001', 'owner', '44444444-4444-4444-4444-444444444444', now()),
  ('d2222222-2222-2222-2222-222222222222', 'sales1@dairydelights.com', crypt('password123', gen_salt('bf', 10)), 'James', 'Taylor', 'Dairy Delights', '+1-555-4002', 'sales_rep', '44444444-4444-4444-4444-444444444444', now()),
  
  -- Supplier 5 (Beverage Solutions) users
  ('e1111111-1111-1111-1111-111111111111', 'owner@beveragesolutions.com', crypt('password123', gen_salt('bf', 10)), 'Patricia', 'Anderson', 'Beverage Solutions Inc.', '+1-555-5001', 'owner', '55555555-5555-5555-5555-555555555555', now()),
  
  -- Consumers (Restaurants/Hotels)
  ('f1111111-1111-1111-1111-111111111111', 'chef@bistromodern.com', crypt('password123', gen_salt('bf', 10)), 'Chef', 'Martinez', 'Bistro Modern', '+1-555-6001', 'consumer', NULL, now()),
  ('f2222222-2222-2222-2222-222222222222', 'manager@grandhotel.com', crypt('password123', gen_salt('bf', 10)), 'Thomas', 'Jackson', 'Grand Hotel', '+1-555-6002', 'consumer', NULL, now()),
  ('f3333333-3333-3333-3333-333333333333', 'purchasing@cafedeluxe.com', crypt('password123', gen_salt('bf', 10)), 'Maria', 'Garcia', 'Cafe Deluxe', '+1-555-6003', 'consumer', NULL, now()),
  ('f4444444-4444-4444-4444-444444444444', 'orders@steakhouse.com', crypt('password123', gen_salt('bf', 10)), 'William', 'White', 'Prime Steakhouse', '+1-555-6004', 'consumer', NULL, now())
ON CONFLICT (email) DO NOTHING;

-- Products (minimal set per supplier for testing)
INSERT INTO products (id, name, description, image_url, unit, price, discount, stock_level, min_order_quantity, supplier_id, category, created_at)
VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Organic Romaine Lettuce', 'Fresh organic romaine lettuce, perfect for salads and wraps', NULL, 'case', 24.99, 0.00, 150, 1, '11111111-1111-1111-1111-111111111111', 'Organic', now()),
  ('a2222221-2222-2222-2222-222222222222', 'Atlantic Salmon Fillet', 'Fresh Atlantic salmon fillets, skin-on, premium grade', NULL, 'lb', 18.99, 0.00, 200, 5, '22222222-2222-2222-2222-222222222222', 'Meat', now()),
  ('a3333331-3333-3333-3333-333333333333', 'Prime Ribeye Steaks', 'USDA Prime ribeye steaks, 12 oz each', NULL, 'piece', 32.99, 0.00, 120, 4, '33333333-3333-3333-3333-333333333333', 'Meat', now()),
  ('a4444441-4444-4444-4444-444444444444', 'Fresh Mozzarella', 'Fresh mozzarella cheese, made daily', NULL, 'lb', 9.99, 0.00, 200, 5, '44444444-4444-4444-4444-444444444444', 'Dairy', now()),
  ('a5555551-5555-5555-5555-555555555555', 'Fresh Orange Juice', '100% fresh squeezed orange juice, no preservatives', NULL, 'gallon', 8.99, 0.00, 200, 2, '55555555-5555-5555-5555-555555555555', 'Seasonal', now())
ON CONFLICT (id) DO NOTHING;

-- Consumer links (include all status variations)
INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at, approved_at)
VALUES
  -- Main consumer with accepted link (used for products/orders)
  ('b1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'accepted', now() - INTERVAL '10 days', now() - INTERVAL '9 days'),
  -- Pending request
  ('b1111112-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'pending', now() - INTERVAL '3 days', NULL),
  -- Completed link (past relationship)
  ('b1111113-1111-1111-1111-111111111111', 'f3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'completed', now() - INTERVAL '30 days', now() - INTERVAL '29 days'),
  -- Rejected request
  ('b1111114-1111-1111-1111-111111111111', 'f4444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 'rejected', now() - INTERVAL '5 days', NULL),
  -- Cancelled link for main consumer with second supplier
  ('b1111115-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'cancelled', now() - INTERVAL '20 days', now() - INTERVAL '19 days')
ON CONFLICT (consumer_id, supplier_id) DO NOTHING;

-- Conversations (single conversation for chat/complaints)
INSERT INTO conversations (id, consumer_id, supplier_id, last_message_at, unread_count, created_at)
VALUES
  ('c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', now() - INTERVAL '1 hour', 0, now() - INTERVAL '10 days')
ON CONFLICT (consumer_id, supplier_id) DO NOTHING;

-- Messages (minimal chat history)
INSERT INTO messages (id, conversation_id, sender_id, sender_role, content, is_read, created_at)
VALUES
  ('c2111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'consumer', 'Hello, I need to place a large order for next week. Can you confirm availability?', true, now() - INTERVAL '2 days'),
  ('c2111112-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', 'sales_rep', 'Hi! Yes, we have good stock levels. What items are you interested in?', true, now() - INTERVAL '2 days' + INTERVAL '1 hour'),
  ('c2111113-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'consumer', 'I need 20 cases of romaine lettuce and 15 cases of tomatoes.', true, now() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Orders (minimal set covering all statuses)
INSERT INTO orders (id, consumer_id, supplier_id, status, subtotal, tax, shipping_fee, total, delivery_date, delivery_start_time, delivery_end_time, notes, preferred_settlement, created_at, updated_at)
VALUES
  -- Pending
  ('d1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'pending', 249.90, 12.50, 10.00, 272.40, (now() + INTERVAL '1 day')::date, '06:00', '09:00', 'Next-day delivery requested with early morning window.', 'Net 15 (USD)', now() - INTERVAL '1 day', now() - INTERVAL '1 day'),
  -- Accepted
  ('d1111112-1111-1111-1111-111111111112', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'accepted', 189.90, 9.50, 10.00, 209.40, (now())::date, '10:00', '13:00', 'Customer prefers product packed on ice.', 'Prepaid (Wire)', now() - INTERVAL '2 days', now() - INTERVAL '1 day'),
  -- Completed
  ('d1111113-1111-1111-1111-111111111113', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'completed', 189.90, 9.50, 8.00, 207.40, (now() - INTERVAL '7 days')::date, '09:00', '11:00', 'Delivered and signed off without issues.', 'Net 14 (USD)', now() - INTERVAL '8 days', now() - INTERVAL '7 days'),
  -- Rejected
  ('d1111114-1111-1111-1111-111111111114', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'rejected', 229.90, 11.50, 10.00, 251.40, (now() - INTERVAL '3 days')::date, '15:00', '18:00', 'Order rejected due to quantity mismatch on delivery.', 'On hold', now() - INTERVAL '4 days', now() - INTERVAL '3 days'),
  -- Cancelled
  ('d1111115-1111-1111-1111-111111111115', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'cancelled', 99.95, 5.00, 5.00, 109.95, (now() + INTERVAL '2 days')::date, '08:00', '10:00', 'Order cancelled by customer prior to shipment.', 'N/A', now() - INTERVAL '1 day', now())
ON CONFLICT (id) DO NOTHING;

-- Order items (matching minimal orders/products)
INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal, created_at)
VALUES
  -- Pending order (Fresh Farm)
  ('e1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 10, 24.99, 249.90, now() - INTERVAL '1 day'),
  -- Accepted order (Fresh Farm)
  ('e1111112-1111-1111-1111-111111111111', 'd1111112-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111', 8, 23.74, 189.92, now() - INTERVAL '2 days'),
  -- Completed order (Ocean Fresh)
  ('e1111113-1111-1111-1111-111111111111', 'd1111113-1111-1111-1111-111111111113', 'a2222221-2222-2222-2222-222222222222', 10, 18.99, 189.90, now() - INTERVAL '8 days'),
  -- Rejected order (Ocean Fresh)
  ('e1111114-1111-1111-1111-111111111111', 'd1111114-1111-1111-1111-111111111114', 'a2222221-2222-2222-2222-222222222222', 12, 19.16, 229.92, now() - INTERVAL '4 days'),
  -- Cancelled order (Fresh Farm)
  ('e1111115-1111-1111-1111-111111111111', 'd1111115-1111-1111-1111-111111111115', 'a1111111-1111-1111-1111-111111111111', 4, 24.99, 99.96, now() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Complaints (single complaint for escalation/resolution testing)
INSERT INTO complaints (id, conversation_id, consumer_id, supplier_id, order_id, title, description, priority, status, created_at)
VALUES
  ('f0111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'd1111113-1111-1111-1111-111111111113', 'Damaged Product', 'Some of the lettuce arrived wilted and unusable.', 'medium', 'open', now() - INTERVAL '7 days')
ON CONFLICT (id) DO NOTHING;

-- Notifications (minimal set)
INSERT INTO notifications (id, user_id, type, title, message, data, is_read, created_at)
VALUES
  ('91111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'order', 'New Order Received', 'You have received a new order #d1111111', jsonb_build_object('order_id', 'd1111111-1111-1111-1111-111111111111'), false, now() - INTERVAL '1 day'),
  ('91111112-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'order', 'Order Accepted', 'Your order #d1111112 has been accepted', jsonb_build_object('order_id', 'd1111112-1111-1111-1111-111111111112'), true, now() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

-- Canned replies (minimal set)
INSERT INTO canned_replies (id, supplier_id, title, content, created_at)
VALUES
  ('fa111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Order Received', 'Thank you for your order! We have received it and will process it shortly.', now()),
  ('fa111112-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Order Confirmed', 'Your order has been confirmed and is being prepared for delivery.', now()),
  ('fa111113-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Delivery Scheduled', 'Your order is scheduled for delivery. We will send you tracking information soon.', now())
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

-- Update unread_count in conversations
UPDATE conversations c
SET unread_count = sub.unread_count
FROM (
  SELECT conversation_id, COUNT(*) AS unread_count
  FROM messages
  WHERE is_read = false
  GROUP BY conversation_id
) sub
WHERE c.id = sub.conversation_id;

-- End of seed
