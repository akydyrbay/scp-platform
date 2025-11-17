package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/scp-platform/backend/internal/models"
)

// Mock repositories
type MockConversationRepository struct {
	mock.Mock
}

func (m *MockConversationRepository) GetByConsumerID(consumerID string) ([]models.Conversation, error) {
	args := m.Called(consumerID)
	return args.Get(0).([]models.Conversation), args.Error(1)
}

func (m *MockConversationRepository) GetBySupplierID(supplierID string) ([]models.Conversation, error) {
	args := m.Called(supplierID)
	return args.Get(0).([]models.Conversation), args.Error(1)
}

func (m *MockConversationRepository) GetOrCreate(consumerID, supplierID string) (*models.Conversation, error) {
	args := m.Called(consumerID, supplierID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Conversation), args.Error(1)
}

func (m *MockConversationRepository) UpdateLastMessage(conversationID string) error {
	args := m.Called(conversationID)
	return args.Error(0)
}

type MockMessageRepository struct {
	mock.Mock
}

func (m *MockMessageRepository) GetByConversationID(conversationID string, page, pageSize int) ([]models.Message, error) {
	args := m.Called(conversationID, page, pageSize)
	return args.Get(0).([]models.Message), args.Error(1)
}

func (m *MockMessageRepository) Create(message *models.Message) error {
	args := m.Called(message)
	return args.Error(0)
}

func (m *MockMessageRepository) MarkAsRead(conversationID string, userID string) error {
	args := m.Called(conversationID, userID)
	return args.Error(0)
}

func TestChatHandler_GetConversations(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		role           string
		userID         string
		supplierID     string
		mockConvs      []models.Conversation
		mockError      error
		expectedStatus int
		checkResults   bool
	}{
		{
			name:       "Consumer gets conversations",
			role:       "consumer",
			userID:     "consumer1",
			mockConvs:  []models.Conversation{{ID: "conv1", ConsumerID: "consumer1"}},
			mockError:  nil,
			expectedStatus: http.StatusOK,
			checkResults: true,
		},
		{
			name:       "Sales rep gets conversations",
			role:       "sales_rep",
			userID:     "sales1",
			supplierID: "supplier1",
			mockConvs:  []models.Conversation{{ID: "conv1", SupplierID: "supplier1"}},
			mockError:  nil,
			expectedStatus: http.StatusOK,
			checkResults: true,
		},
		{
			name:       "Unauthorized role",
			role:       "invalid",
			userID:     "user1",
			expectedStatus: http.StatusForbidden,
			checkResults: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockConvRepo := new(MockConversationRepository)
			mockMsgRepo := new(MockMessageRepository)

			if tt.role == "consumer" {
				mockConvRepo.On("GetByConsumerID", tt.userID).Return(tt.mockConvs, tt.mockError)
			} else if tt.role == "sales_rep" {
				mockConvRepo.On("GetBySupplierID", tt.supplierID).Return(tt.mockConvs, tt.mockError)
			}

			handler := NewChatHandler(mockConvRepo, mockMsgRepo)

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Set("user_id", tt.userID)
			c.Set("role", tt.role)
			if tt.supplierID != "" {
				c.Set("supplier_id", tt.supplierID)
			}

			handler.GetConversations(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.checkResults {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				assert.NotNil(t, response["results"])
			}

			mockConvRepo.AssertExpectations(t)
		})
	}
}

func TestChatHandler_GetMessages(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockConvRepo := new(MockConversationRepository)
	mockMsgRepo := new(MockMessageRepository)

	mockMessages := []models.Message{
		{ID: "msg1", ConversationID: "conv1", Content: "Hello"},
	}

	mockMsgRepo.On("GetByConversationID", "conv1", 1, 50).Return(mockMessages, nil)

	handler := NewChatHandler(mockConvRepo, mockMsgRepo)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Params = gin.Params{{Key: "id", Value: "conv1"}}
	c.Request = httptest.NewRequest("GET", "/conversations/conv1/messages?page=1&page_size=50", nil)

	handler.GetMessages(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotNil(t, response["results"])

	mockMsgRepo.AssertExpectations(t)
}

