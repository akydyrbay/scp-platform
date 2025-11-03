-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consumer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP,
    unread_count INTEGER NOT NULL DEFAULT 0 CHECK (unread_count >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    UNIQUE(consumer_id, supplier_id)
);

CREATE INDEX idx_conversations_consumer_id ON conversations(consumer_id);
CREATE INDEX idx_conversations_supplier_id ON conversations(supplier_id);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at DESC);

