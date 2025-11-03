package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/models"
	"github.com/scp-platform/backend/internal/repository"
)

type ChatHandler struct {
	conversationRepo *repository.ConversationRepository
	messageRepo      *repository.MessageRepository
}

func NewChatHandler(conversationRepo *repository.ConversationRepository, messageRepo *repository.MessageRepository) *ChatHandler {
	return &ChatHandler{
		conversationRepo: conversationRepo,
		messageRepo:      messageRepo,
	}
}

func (h *ChatHandler) GetConversations(c *gin.Context) {
	userID := c.GetString("user_id")
	role := c.GetString("role")

	var conversations []models.Conversation
	var err error

	if role == "consumer" {
		conversations, err = h.conversationRepo.GetByConsumerID(userID)
	} else if role == "sales_rep" {
		supplierID := c.GetString("supplier_id")
		conversations, err = h.conversationRepo.GetBySupplierID(supplierID)
	} else {
		c.JSON(http.StatusForbidden, ErrorResponse("Unauthorized role"))
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(conversations))
}

func (h *ChatHandler) GetMessages(c *gin.Context) {
	conversationID := c.Param("id")
	page, pageSize := ParsePagination(c)

	messages, err := h.messageRepo.GetByConversationID(conversationID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(messages, page, pageSize, len(messages)))
}

func (h *ChatHandler) SendMessage(c *gin.Context) {
	conversationID := c.Param("id")
	senderID := c.GetString("user_id")
	senderRole := c.GetString("role")

	var req struct {
		Content       string  `json:"content" binding:"required"`
		AttachmentURL *string `json:"attachment_url"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
		return
	}

	// Get or create conversation
	var conversation *models.Conversation
	var err error

	if senderRole == "consumer" {
		supplierID := c.Query("supplier_id")
		if supplierID == "" {
			c.JSON(http.StatusBadRequest, ErrorResponse("supplier_id required"))
			return
		}
		conversation, err = h.conversationRepo.GetOrCreate(senderID, supplierID)
	} else {
		consumerID := c.Query("consumer_id")
		if consumerID == "" {
			c.JSON(http.StatusBadRequest, ErrorResponse("consumer_id required"))
			return
		}
		conversation, err = h.conversationRepo.GetOrCreate(consumerID, c.GetString("supplier_id"))
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	message := &models.Message{
		ConversationID: conversation.ID,
		SenderID:       senderID,
		SenderRole:     senderRole,
		Content:        req.Content,
		AttachmentURL:  req.AttachmentURL,
		IsRead:         false,
	}

	if err := h.messageRepo.Create(message); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Update conversation last message time
	h.conversationRepo.UpdateLastMessage(conversation.ID)

	c.JSON(http.StatusCreated, SuccessResponse(message))
}

func (h *ChatHandler) MarkMessagesAsRead(c *gin.Context) {
	conversationID := c.Param("id")
	userID := c.GetString("user_id")

	if err := h.messageRepo.MarkAsRead(conversationID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(gin.H{"message": "Messages marked as read"}))
}

