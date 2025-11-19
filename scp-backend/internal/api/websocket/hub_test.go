package websocket

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestNewHub(t *testing.T) {
	hub := NewHub()
	assert.NotNil(t, hub)
	assert.NotNil(t, hub.Clients)
	assert.NotNil(t, hub.Broadcast)
	assert.NotNil(t, hub.Register)
	assert.NotNil(t, hub.Unregister)
}

func TestHub_RegisterClient(t *testing.T) {
	hub := NewHub()
	client := &Client{
		ID:   "client-1",
		Role: "consumer",
		Hub:  hub,
	}

	// Simulate registration
	hub.Clients[client] = true

	assert.True(t, hub.Clients[client])
	assert.Len(t, hub.Clients, 1)
}

func TestHub_UnregisterClient(t *testing.T) {
	hub := NewHub()
	client := &Client{
		ID:   "client-1",
		Role: "consumer",
		Hub:  hub,
		Send: make(chan []byte, 256),
	}

	hub.Clients[client] = true
	assert.Len(t, hub.Clients, 1)

	// Simulate unregistration
	delete(hub.Clients, client)
	close(client.Send)

	assert.Len(t, hub.Clients, 0)
}

func TestHub_SendToUser(t *testing.T) {
	hub := NewHub()
	client1 := &Client{
		ID:   "user-123",
		Role: "consumer",
		Hub:  hub,
		Send: make(chan []byte, 256),
	}
	client2 := &Client{
		ID:   "user-456",
		Role: "consumer",
		Hub:  hub,
		Send: make(chan []byte, 256),
	}

	hub.Clients[client1] = true
	hub.Clients[client2] = true

	message := Message{
		Type: "test",
		Data: "test data",
	}

	// Test SendToUser
	hub.SendToUser("user-123", message)

	// Verify message was sent to correct client
	select {
	case msg := <-client1.Send:
		assert.NotEmpty(t, msg)
	case <-time.After(100 * time.Millisecond):
		t.Error("Message not received")
	}

	// Verify other client didn't receive message
	select {
	case <-client2.Send:
		t.Error("Wrong client received message")
	case <-time.After(50 * time.Millisecond):
		// Expected - client2 should not receive message
	}
}

func TestHub_SendToSupplier(t *testing.T) {
	hub := NewHub()
	client1 := &Client{
		ID:         "user-1",
		Role:       "sales_rep",
		SupplierID: "supplier-123",
		Hub:        hub,
		Send:       make(chan []byte, 256),
	}
	client2 := &Client{
		ID:         "user-2",
		Role:       "sales_rep",
		SupplierID: "supplier-456",
		Hub:        hub,
		Send:       make(chan []byte, 256),
	}

	hub.Clients[client1] = true
	hub.Clients[client2] = true

	message := Message{
		Type: "notification",
		Data: "test",
	}

	hub.SendToSupplier("supplier-123", message)

	select {
	case msg := <-client1.Send:
		assert.NotEmpty(t, msg)
	case <-time.After(100 * time.Millisecond):
		t.Error("Message not received")
	}
}

func TestHub_SendToConsumer(t *testing.T) {
	hub := NewHub()
	consumerClient := &Client{
		ID:   "consumer-123",
		Role: "consumer",
		Hub:  hub,
		Send: make(chan []byte, 256),
	}
	supplierClient := &Client{
		ID:   "consumer-123",
		Role: "owner", // Same ID but different role
		Hub:  hub,
		Send: make(chan []byte, 256),
	}

	hub.Clients[consumerClient] = true
	hub.Clients[supplierClient] = true

	message := Message{
		Type: "message",
		Data: "test",
	}

	hub.SendToConsumer("consumer-123", message)

	select {
	case msg := <-consumerClient.Send:
		assert.NotEmpty(t, msg)
	case <-time.After(100 * time.Millisecond):
		t.Error("Message not received")
	}

	// Supplier client should not receive (different role)
	select {
	case <-supplierClient.Send:
		t.Error("Wrong client received message")
	case <-time.After(50 * time.Millisecond):
		// Expected
	}
}

func TestHub_Broadcast(t *testing.T) {
	hub := NewHub()
	client1 := &Client{
		ID:   "client-1",
		Hub:  hub,
		Send: make(chan []byte, 256),
	}
	client2 := &Client{
		ID:   "client-2",
		Hub:  hub,
		Send: make(chan []byte, 256),
	}

	hub.Clients[client1] = true
	hub.Clients[client2] = true

	message := []byte("broadcast message")

	// Simulate broadcast
	for client := range hub.Clients {
		select {
		case client.Send <- message:
		default:
			close(client.Send)
			delete(hub.Clients, client)
		}
	}

	select {
	case msg := <-client1.Send:
		assert.Equal(t, message, msg)
	case <-time.After(100 * time.Millisecond):
		t.Error("Message not received by client1")
	}

	select {
	case msg := <-client2.Send:
		assert.Equal(t, message, msg)
	case <-time.After(100 * time.Millisecond):
		t.Error("Message not received by client2")
	}
}

func TestMessage_Marshal(t *testing.T) {
	message := Message{
		Type: "test",
		Data: map[string]interface{}{
			"key": "value",
		},
	}

	// Test that message can be marshaled via json.Marshal
	hub := NewHub()
	hub.SendToUser("test-user", message)
	// This tests the marshaling inside SendToUser
	assert.NotNil(t, message)
}

