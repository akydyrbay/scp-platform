-- Seed sample data for development/testing
-- This file inserts representative rows for each table created by earlier migrations.
-- It uses fixed UUIDs so foreign key references are explicit.
-- NOTE: This migration creates the pgcrypto extension to generate bcrypt hashes for passwords.

-- Enable pgcrypto for crypt() and gen_salt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Suppliers (Multiple realistic suppliers)
INSERT INTO suppliers (id, name, description, email, phone_number, address, created_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Fresh Farm Produce Co.', 'Premium fresh vegetables and fruits supplier for restaurants and hotels', 'contact@freshfarm.com', '+1-555-0101', '1234 Agriculture Blvd, Farm City, FC 12345', now()),
  ('22222222-2222-2222-2222-222222222222', 'Ocean Fresh Seafood', 'High-quality fresh seafood and fish products', 'sales@oceanfresh.com', '+1-555-0202', '5678 Harbor Way, Coastal City, CC 23456', now()),
  ('33333333-3333-3333-3333-333333333333', 'Premium Meats & Poultry', 'Premium quality beef, pork, chicken, and lamb', 'orders@premiummeats.com', '+1-555-0303', '9012 Ranch Road, Meat City, MC 34567', now()),
  ('44444444-4444-4444-4444-444444444444', 'Dairy Delights', 'Fresh dairy products, cheese, and specialty items', 'info@dairydelights.com', '+1-555-0404', '3456 Farm Lane, Dairy Town, DT 45678', now()),
  ('55555555-5555-5555-5555-555555555555', 'Beverage Solutions Inc.', 'Wide selection of beverages, juices, and soft drinks', 'sales@beveragesolutions.com', '+1-555-0505', '7890 Drink Avenue, Beverage City, BC 56789', now())
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

-- Products (Realistic food service products)
-- Fixed: Changed 'p' prefix to 'a' (valid hex) for product IDs
INSERT INTO products (id, name, description, image_url, unit, price, discount, stock_level, min_order_quantity, supplier_id, created_at)
VALUES
  -- Fresh Farm Produce Co. products
  ('a1111111-1111-1111-1111-111111111111', 'Organic Romaine Lettuce', 'Fresh organic romaine lettuce, perfect for salads and wraps', NULL, 'case', 24.99, 0.00, 150, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111112-1111-1111-1111-111111111111', 'Premium Tomatoes', 'Vine-ripened premium tomatoes, ideal for salads and cooking', NULL, 'case', 32.50, 5.00, 200, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111113-1111-1111-1111-111111111111', 'Fresh Carrots', 'Fresh whole carrots, cleaned and ready to use', NULL, 'case', 18.75, 0.00, 300, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111114-1111-1111-1111-111111111111', 'Baby Spinach', 'Fresh baby spinach leaves, pre-washed and ready to serve', NULL, 'case', 28.99, 0.00, 120, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111115-1111-1111-1111-111111111111', 'Red Bell Peppers', 'Premium red bell peppers, sweet and crisp', NULL, 'case', 35.00, 0.00, 180, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111116-1111-1111-1111-111111111111', 'Fresh Onions', 'Yellow onions, perfect for cooking and salads', NULL, 'case', 15.50, 0.00, 250, 1, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111117-1111-1111-1111-111111111111', 'Garlic Cloves', 'Fresh garlic cloves, premium quality', NULL, 'lb', 4.99, 0.00, 500, 5, '11111111-1111-1111-1111-111111111111', now()),
  ('a1111118-1111-1111-1111-111111111111', 'Fresh Basil', 'Fresh basil leaves, aromatic and flavorful', NULL, 'bunch', 3.50, 0.00, 100, 10, '11111111-1111-1111-1111-111111111111', now()),
  
  -- Ocean Fresh Seafood products
  ('a2222221-2222-2222-2222-222222222222', 'Atlantic Salmon Fillet', 'Fresh Atlantic salmon fillets, skin-on, premium grade', NULL, 'lb', 18.99, 0.00, 200, 5, '22222222-2222-2222-2222-222222222222', now()),
  ('a2222222-2222-2222-2222-222222222222', 'Wild Caught Shrimp', 'Large wild-caught shrimp, 16/20 count per pound', NULL, 'lb', 24.50, 10.00, 150, 5, '22222222-2222-2222-2222-222222222222', now()),
  ('a2222223-2222-2222-2222-222222222222', 'Fresh Tuna Steaks', 'Premium fresh tuna steaks, sushi-grade', NULL, 'lb', 22.99, 0.00, 80, 3, '22222222-2222-2222-2222-222222222222', now()),
  ('a2222224-2222-2222-2222-222222222222', 'Lobster Tails', 'Fresh lobster tails, 6-8 oz each', NULL, 'piece', 28.00, 0.00, 60, 2, '22222222-2222-2222-2222-222222222222', now()),
  ('a2222225-2222-2222-2222-222222222222', 'Fresh Scallops', 'Large sea scallops, U-10 count', NULL, 'lb', 26.75, 0.00, 100, 3, '22222222-2222-2222-2222-222222222222', now()),
  ('a2222226-2222-2222-2222-222222222222', 'Cod Fillets', 'Fresh cod fillets, boneless and skinless', NULL, 'lb', 12.99, 0.00, 180, 5, '22222222-2222-2222-2222-222222222222', now()),
  
  -- Premium Meats & Poultry products
  ('a3333331-3333-3333-3333-333333333333', 'Prime Ribeye Steaks', 'USDA Prime ribeye steaks, 12 oz each', NULL, 'piece', 32.99, 0.00, 120, 4, '33333333-3333-3333-3333-333333333333', now()),
  ('a3333332-3333-3333-3333-333333333333', 'Wagyu Beef Strips', 'Premium Wagyu beef strips, marbled and tender', NULL, 'lb', 45.00, 5.00, 50, 2, '33333333-3333-3333-3333-333333333333', now()),
  ('a3333333-3333-3333-3333-333333333333', 'Chicken Breast', 'Boneless skinless chicken breast, premium quality', NULL, 'lb', 8.99, 0.00, 400, 10, '33333333-3333-3333-3333-333333333333', now()),
  ('a3333334-3333-3333-3333-333333333333', 'Pork Tenderloin', 'Fresh pork tenderloin, trimmed and ready', NULL, 'lb', 11.50, 0.00, 200, 5, '33333333-3333-3333-3333-333333333333', now()),
  ('a3333335-3333-3333-3333-333333333333', 'Ground Beef', 'Premium ground beef, 80/20 blend', NULL, 'lb', 7.99, 0.00, 300, 10, '33333333-3333-3333-3333-333333333333', now()),
  ('a3333336-3333-3333-3333-333333333333', 'Lamb Chops', 'Frenched lamb chops, premium quality', NULL, 'piece', 18.50, 0.00, 150, 4, '33333333-3333-3333-3333-333333333333', now()),
  
  -- Dairy Delights products
  ('a4444441-4444-4444-4444-444444444444', 'Fresh Mozzarella', 'Fresh mozzarella cheese, made daily', NULL, 'lb', 9.99, 0.00, 200, 5, '44444444-4444-4444-4444-444444444444', now()),
  ('a4444442-4444-4444-4444-444444444444', 'Aged Parmesan', '24-month aged Parmesan cheese, grated', NULL, 'lb', 16.50, 0.00, 150, 2, '44444444-4444-4444-4444-444444444444', now()),
  ('a4444443-4444-4444-4444-444444444444', 'Heavy Cream', 'Fresh heavy cream, 40% butterfat', NULL, 'gallon', 12.99, 0.00, 100, 2, '44444444-4444-4444-4444-444444444444', now()),
  ('a4444444-4444-4444-4444-444444444444', 'Butter', 'Premium European-style butter, unsalted', NULL, 'lb', 6.99, 0.00, 250, 5, '44444444-4444-4444-4444-444444444444', now()),
  ('a4444445-4444-4444-4444-444444444444', 'Greek Yogurt', 'Premium Greek yogurt, full-fat', NULL, 'case', 28.00, 0.00, 120, 1, '44444444-4444-4444-4444-444444444444', now()),
  ('a4444446-4444-4444-4444-444444444444', 'Goat Cheese', 'Fresh goat cheese, creamy and tangy', NULL, 'lb', 11.99, 0.00, 80, 2, '44444444-4444-4444-4444-444444444444', now()),
  
  -- Beverage Solutions Inc. products
  ('a5555551-5555-5555-5555-555555555555', 'Fresh Orange Juice', '100% fresh squeezed orange juice, no preservatives', NULL, 'gallon', 8.99, 0.00, 200, 2, '55555555-5555-5555-5555-555555555555', now()),
  ('a5555552-5555-5555-5555-555555555555', 'Premium Coffee Beans', 'Arabica coffee beans, medium roast', NULL, 'lb', 14.99, 0.00, 300, 5, '55555555-5555-5555-5555-555555555555', now()),
  ('a5555553-5555-5555-5555-555555555555', 'Sparkling Water', 'Premium sparkling water, 12-pack', NULL, 'case', 18.50, 0.00, 180, 1, '55555555-5555-5555-5555-555555555555', now()),
  ('a5555554-5555-5555-5555-555555555555', 'Craft Beer Selection', 'Assorted craft beers, 24-pack', NULL, 'case', 45.00, 10.00, 100, 1, '55555555-5555-5555-5555-555555555555', now()),
  ('a5555555-5555-5555-5555-555555555555', 'Wine Selection', 'Premium wine selection, red and white', NULL, 'case', 120.00, 0.00, 60, 1, '55555555-5555-5555-5555-555555555555', now())
ON CONFLICT (id) DO NOTHING;

-- Consumer links (consumers linked to suppliers)
-- Fixed: Changed 'l' prefix to 'b' (valid hex) for consumer link IDs
INSERT INTO consumer_links (id, consumer_id, supplier_id, status, requested_at, approved_at)
VALUES
  ('b1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'approved', now() - INTERVAL '30 days', now() - INTERVAL '29 days'),
  ('b1111112-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'approved', now() - INTERVAL '25 days', now() - INTERVAL '24 days'),
  ('b1111113-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'approved', now() - INTERVAL '20 days', now() - INTERVAL '19 days'),
  ('b1111114-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'approved', now() - INTERVAL '15 days', now() - INTERVAL '14 days'),
  ('b1111115-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'approved', now() - INTERVAL '10 days', now() - INTERVAL '9 days'),
  ('b1111116-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 'approved', now() - INTERVAL '5 days', now() - INTERVAL '4 days'),
  ('b1111117-1111-1111-1111-111111111111', 'f3333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'pending', now() - INTERVAL '3 days', NULL),
  ('b1111118-1111-1111-1111-111111111111', 'f4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'approved', now() - INTERVAL '7 days', now() - INTERVAL '6 days')
ON CONFLICT (consumer_id, supplier_id) DO NOTHING;

-- Conversations
INSERT INTO conversations (id, consumer_id, supplier_id, last_message_at, unread_count, created_at)
VALUES
  ('c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', now() - INTERVAL '1 hour', 0, now() - INTERVAL '10 days'),
  ('c1111112-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', now() - INTERVAL '2 hours', 1, now() - INTERVAL '8 days'),
  ('c1111113-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', now() - INTERVAL '30 minutes', 0, now() - INTERVAL '5 days'),
  ('c1111114-1111-1111-1111-111111111111', 'f4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', now() - INTERVAL '1 day', 2, now() - INTERVAL '3 days')
ON CONFLICT (consumer_id, supplier_id) DO NOTHING;

-- Messages
-- Fixed: Changed 'm' prefix to 'c' (valid hex) for message IDs (note: 'c' already used for conversations, but UUIDs can overlap)
INSERT INTO messages (id, conversation_id, sender_id, sender_role, content, is_read, created_at)
VALUES
  -- Conversation 1
  ('c2111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'consumer', 'Hello, I need to place a large order for next week. Can you confirm availability?', true, now() - INTERVAL '2 days'),
  ('c2111112-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', 'sales_rep', 'Hi! Yes, we have good stock levels. What items are you interested in?', true, now() - INTERVAL '2 days' + INTERVAL '1 hour'),
  ('c2111113-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'consumer', 'I need 20 cases of romaine lettuce and 15 cases of tomatoes.', true, now() - INTERVAL '1 day'),
  ('c2111114-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', 'sales_rep', 'Perfect! I can confirm both items are available. Should I prepare the order?', true, now() - INTERVAL '1 hour'),
  
  -- Conversation 2
  ('c2222221-2222-2222-2222-222222222222', 'c1111112-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'consumer', 'Do you have fresh salmon available this week?', true, now() - INTERVAL '3 days'),
  ('c2222222-2222-2222-2222-222222222222', 'c1111112-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222', 'sales_rep', 'Yes, we received a fresh shipment yesterday. How much do you need?', false, now() - INTERVAL '2 hours'),
  
  -- Conversation 3
  ('c2333331-3333-3333-3333-333333333333', 'c1111113-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', 'consumer', 'Thank you for the quick delivery last week!', true, now() - INTERVAL '5 days'),
  ('c2333332-3333-3333-3333-333333333333', 'c1111113-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', 'sales_rep', 'You are welcome! We are happy to serve you.', true, now() - INTERVAL '4 days'),
  ('c2333333-3333-3333-3333-333333333333', 'c1111113-1111-1111-1111-111111111111', 'f2222222-2222-2222-2222-222222222222', 'consumer', 'I will place another order soon.', true, now() - INTERVAL '30 minutes'),
  
  -- Conversation 4
  ('c2444441-4444-4444-4444-444444444444', 'c1111114-1111-1111-1111-111111111111', 'f4444444-4444-4444-4444-444444444444', 'consumer', 'I need premium ribeye steaks for a special event. Do you have any available?', true, now() - INTERVAL '3 days'),
  ('c2444442-4444-4444-4444-444444444444', 'c1111114-1111-1111-1111-111111111111', 'c2222222-2222-2222-2222-222222222222', 'sales_rep', 'Yes, we have excellent stock. How many do you need?', false, now() - INTERVAL '1 day'),
  ('c2444443-4444-4444-4444-444444444444', 'c1111114-1111-1111-1111-111111111111', 'f4444444-4444-4444-4444-444444444444', 'consumer', 'I need 50 steaks for Saturday.', false, now() - INTERVAL '12 hours')
ON CONFLICT (id) DO NOTHING;

-- Orders (Various statuses)
-- Fixed: Changed 'o' prefix to 'd' (valid hex) for order IDs
-- Note: Subtotals will be recalculated from order_items at the end
INSERT INTO orders (id, consumer_id, supplier_id, status, subtotal, tax, shipping_fee, total, created_at, updated_at)
VALUES
  -- Pending orders
  ('d1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'pending', 963.00, 48.15, 15.00, 1026.15, now() - INTERVAL '2 days', now() - INTERVAL '2 days'),
  ('d1111112-1111-1111-1111-111111111112', 'f2222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'pending', 464.75, 23.24, 20.00, 507.99, now() - INTERVAL '1 day', now() - INTERVAL '1 day'),
  
  -- Accepted orders
  ('d1111113-1111-1111-1111-111111111113', 'f1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'accepted', 234.00, 11.70, 10.00, 255.70, now() - INTERVAL '5 days', now() - INTERVAL '4 days'),
  ('d1111114-1111-1111-1111-111111111114', 'f2222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'accepted', 362.50, 18.13, 12.00, 392.63, now() - INTERVAL '3 days', now() - INTERVAL '2 days'),
  
  -- Completed orders
  ('d1111115-1111-1111-1111-111111111115', 'f1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'completed', 84.90, 4.25, 8.00, 97.15, now() - INTERVAL '10 days', now() - INTERVAL '8 days'),
  ('d1111116-1111-1111-1111-111111111116', 'f4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'completed', 659.80, 32.99, 25.00, 717.79, now() - INTERVAL '7 days', now() - INTERVAL '6 days'),
  
  -- Rejected order
  ('d1111117-1111-1111-1111-111111111117', 'f3333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222', 'rejected', 183.92, 9.20, 10.00, 203.12, now() - INTERVAL '4 days', now() - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

-- Order items
-- Fixed: Changed 'oi' prefix to 'e1' (valid hex) for order item IDs
-- Fixed: Changed 'o' prefix to 'd' for order_id references
-- Fixed: Changed 'p' prefix to 'a' for product_id references
INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal, created_at)
VALUES
  -- Order 1 (Pending - Fresh Farm)
  ('e1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 20, 24.99, 499.80, now() - INTERVAL '2 days'),
  ('e1111112-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'a1111112-1111-1111-1111-111111111111', 15, 30.88, 463.20, now() - INTERVAL '2 days'),
  
  -- Order 2 (Pending - Premium Meats)
  ('e1111113-1111-1111-1111-111111111111', 'd1111112-1111-1111-1111-111111111112', 'a3333331-3333-3333-3333-333333333333', 10, 32.99, 329.90, now() - INTERVAL '1 day'),
  ('e1111114-1111-1111-1111-111111111111', 'd1111112-1111-1111-1111-111111111112', 'a3333333-3333-3333-3333-333333333333', 15, 8.99, 134.85, now() - INTERVAL '1 day'),
  
  -- Order 3 (Accepted - Ocean Fresh)
  ('e1111115-1111-1111-1111-111111111111', 'd1111113-1111-1111-1111-111111111113', 'a2222221-2222-2222-2222-222222222222', 10, 18.99, 189.90, now() - INTERVAL '5 days'),
  ('e1111116-1111-1111-1111-111111111111', 'd1111113-1111-1111-1111-111111111113', 'a2222222-2222-2222-2222-222222222222', 2, 22.05, 44.10, now() - INTERVAL '5 days'),
  
  -- Order 4 (Accepted - Fresh Farm)
  ('e1111117-1111-1111-1111-111111111111', 'd1111114-1111-1111-1111-111111111114', 'a1111113-1111-1111-1111-111111111111', 10, 18.75, 187.50, now() - INTERVAL '3 days'),
  ('e1111118-1111-1111-1111-111111111111', 'd1111114-1111-1111-1111-111111111114', 'a1111115-1111-1111-1111-111111111111', 5, 35.00, 175.00, now() - INTERVAL '3 days'),
  
  -- Order 5 (Completed - Dairy Delights)
  ('e1111119-1111-1111-1111-111111111111', 'd1111115-1111-1111-1111-111111111115', 'a4444441-4444-4444-4444-444444444444', 5, 9.99, 49.95, now() - INTERVAL '10 days'),
  ('e1111120-1111-1111-1111-111111111111', 'd1111115-1111-1111-1111-111111111115', 'a4444444-4444-4444-4444-444444444444', 5, 6.99, 34.95, now() - INTERVAL '10 days'),
  
  -- Order 6 (Completed - Premium Meats)
  ('e1111121-1111-1111-1111-111111111111', 'd1111116-1111-1111-1111-111111111116', 'a3333331-3333-3333-3333-333333333333', 20, 32.99, 659.80, now() - INTERVAL '7 days'),
  
  -- Order 7 (Rejected - Ocean Fresh)
  ('e1111122-1111-1111-1111-111111111111', 'd1111117-1111-1111-1111-111111111117', 'a2222223-2222-2222-2222-222222222222', 8, 22.99, 183.92, now() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- Complaints
-- Fixed: Changed 'co' prefix to 'f0' (valid hex) for complaint IDs
-- Fixed: Changed 'o' prefix to 'd' for order_id references
INSERT INTO complaints (id, conversation_id, consumer_id, supplier_id, order_id, title, description, priority, status, created_at)
VALUES
  ('f0111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'd1111115-1111-1111-1111-111111111115', 'Damaged Product', 'Some of the lettuce arrived wilted and unusable.', 'medium', 'open', now() - INTERVAL '9 days'),
  ('f0111112-1111-1111-1111-111111111111', 'c1111114-1111-1111-1111-111111111111', 'f4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'd1111116-1111-1111-1111-111111111116', 'Late Delivery', 'Order was delivered 2 days late, affecting our event.', 'high', 'escalated', now() - INTERVAL '6 days')
ON CONFLICT (id) DO NOTHING;

-- Notifications
-- Fixed: Changed 'n' prefix to '9' (valid hex) for notification IDs
-- Fixed: Changed 'o' prefix to 'd' for order_id references in JSON
INSERT INTO notifications (id, user_id, type, title, message, data, is_read, created_at)
VALUES
  ('91111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'order', 'New Order Received', 'You have received a new order #d1111111', jsonb_build_object('order_id', 'd1111111-1111-1111-1111-111111111111'), false, now() - INTERVAL '2 days'),
  ('91111112-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'order', 'New Order Received', 'You have received a new order #d1111114', jsonb_build_object('order_id', 'd1111114-1111-1111-1111-111111111114'), true, now() - INTERVAL '3 days'),
  ('91111113-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111', 'order', 'New Order Received', 'You have received a new order #d1111113', jsonb_build_object('order_id', 'd1111113-1111-1111-1111-111111111113'), true, now() - INTERVAL '5 days'),
  ('91111114-1111-1111-1111-111111111111', 'a3333333-3333-3333-3333-333333333333', 'message', 'New Message', 'You have a new message from Bistro Modern', jsonb_build_object('conversation_id', 'c1111111-1111-1111-1111-111111111111'), false, now() - INTERVAL '1 hour'),
  ('91111115-1111-1111-1111-111111111111', 'f1111111-1111-1111-1111-111111111111', 'order', 'Order Accepted', 'Your order #d1111113 has been accepted', jsonb_build_object('order_id', 'd1111113-1111-1111-1111-111111111113'), true, now() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- Canned replies
-- Fixed: Changed 'cr' prefix to 'fa' (valid hex) for canned reply IDs
INSERT INTO canned_replies (id, supplier_id, title, content, created_at)
VALUES
  ('fa111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Order Received', 'Thank you for your order! We have received it and will process it shortly.', now()),
  ('fa111112-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Order Confirmed', 'Your order has been confirmed and is being prepared for delivery.', now()),
  ('fa111113-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Delivery Scheduled', 'Your order is scheduled for delivery. We will send you tracking information soon.', now()),
  ('fa111114-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'Availability Check', 'Let me check the availability of that item for you right away.', now()),
  ('fa111115-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', 'Thank You', 'Thank you for choosing Premium Meats & Poultry! How can I assist you today?', now())
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
