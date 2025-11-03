-- Create consumer_links table
CREATE TABLE IF NOT EXISTS consumer_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'blocked')),
    requested_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMP,
    blocked_at TIMESTAMP,
    UNIQUE(consumer_id, supplier_id)
);

CREATE INDEX idx_consumer_links_consumer_id ON consumer_links(consumer_id);
CREATE INDEX idx_consumer_links_supplier_id ON consumer_links(supplier_id);
CREATE INDEX idx_consumer_links_status ON consumer_links(status);

