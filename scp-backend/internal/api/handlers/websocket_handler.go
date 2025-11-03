package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/scp-platform/backend/internal/api/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Configure properly for production
	},
}

type WebSocketHandler struct {
	Hub *websocket.Hub
}

func NewWebSocketHandler(hub *websocket.Hub) *WebSocketHandler {
	return &WebSocketHandler{
		Hub: hub,
	}
}

func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}

	userID := c.GetString("user_id")
	role := c.GetString("role")
	supplierID := c.GetString("supplier_id")

	client := &websocket.Client{
		ID:         userID,
		Role:       role,
		SupplierID: supplierID,
		Conn:       conn,
		Send:       make(chan []byte, 256),
		Hub:        h.Hub,
	}

	client.Hub.Register <- client

	go client.WritePump()
	client.ReadPump()
}

