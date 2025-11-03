-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    unit VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    discount DECIMAL(5, 2) CHECK (discount >= 0 AND discount <= 100),
    stock_level INTEGER NOT NULL DEFAULT 0 CHECK (stock_level >= 0),
    min_order_quantity INTEGER NOT NULL DEFAULT 1 CHECK (min_order_quantity > 0),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX idx_products_supplier_id ON products(supplier_id);
CREATE INDEX idx_products_stock_level ON products(stock_level);

