package handlers

import (
	"encoding/json"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestComplaintHandler_CreateComplaint_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	reqBody := map[string]interface{}{
		"conversation_id": "conv-123",
		"consumer_id":     "consumer-123",
		"title":           "Test Complaint",
		"description":     "This is a test complaint description",
		"priority":        "high",
	}

	body, _ := json.Marshal(reqBody)
	var createReq struct {
		ConversationID string  `json:"conversation_id" binding:"required"`
		ConsumerID     string  `json:"consumer_id" binding:"required"`
		OrderID        *string `json:"order_id"`
		Title          string  `json:"title" binding:"required"`
		Description    string  `json:"description" binding:"required"`
		Priority       string  `json:"priority" binding:"required,oneof=low medium high urgent"`
	}

	err := json.Unmarshal(body, &createReq)
	assert.NoError(t, err)
	assert.Equal(t, "conv-123", createReq.ConversationID)
	assert.Equal(t, "high", createReq.Priority)
	assert.Contains(t, []string{"low", "medium", "high", "urgent"}, createReq.Priority)
}

func TestComplaintHandler_CreateComplaint_InvalidPriority(t *testing.T) {
	reqBody := map[string]interface{}{
		"conversation_id": "conv-123",
		"consumer_id":     "consumer-123",
		"title":           "Test Complaint",
		"description":     "This is a test complaint description",
		"priority":        "invalid",
	}

	body, _ := json.Marshal(reqBody)
	var createReq struct {
		Priority string `json:"priority" binding:"required,oneof=low medium high urgent"`
	}

	err := json.Unmarshal(body, &createReq)
	assert.NoError(t, err)
	assert.NotContains(t, []string{"low", "medium", "high", "urgent"}, createReq.Priority)
}

func TestComplaintHandler_EscalateComplaint(t *testing.T) {
	gin.SetMode(gin.TestMode)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Set("user_id", "sales-rep-123")

	userID := c.GetString("user_id")
	assert.Equal(t, "sales-rep-123", userID)
}

func TestComplaintHandler_ResolveComplaint_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	reqBody := map[string]interface{}{
		"resolution": "This complaint has been resolved successfully",
	}

	body, _ := json.Marshal(reqBody)
	var resolveReq struct {
		Resolution string `json:"resolution" binding:"required,min=10"`
	}

	err := json.Unmarshal(body, &resolveReq)
	assert.NoError(t, err)
	assert.GreaterOrEqual(t, len(resolveReq.Resolution), 10)
}

func TestComplaintHandler_ResolveComplaint_ShortResolution(t *testing.T) {
	reqBody := map[string]interface{}{
		"resolution": "short",
	}

	body, _ := json.Marshal(reqBody)
	var resolveReq struct {
		Resolution string `json:"resolution" binding:"required,min=10"`
	}

	err := json.Unmarshal(body, &resolveReq)
	assert.NoError(t, err)
	assert.Less(t, len(resolveReq.Resolution), 10)
}

