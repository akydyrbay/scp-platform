package handlers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/scp-platform/backend/internal/models"
)

// MessageResponse transforms backend Message model to Flutter-compatible format
func MessageResponse(msg *models.Message) gin.H {
	senderName := "Unknown User"
	if msg.Sender != nil {
		if msg.Sender.FirstName != nil && msg.Sender.LastName != nil {
			senderName = *msg.Sender.FirstName + " " + *msg.Sender.LastName
		} else if msg.Sender.FirstName != nil {
			senderName = *msg.Sender.FirstName
		} else if msg.Sender.CompanyName != nil {
			senderName = *msg.Sender.CompanyName
		} else if msg.Sender.Email != "" {
			senderName = msg.Sender.Email
		}
	} else {
		// Fallback: use sender_id if sender info not available
		senderName = "User " + msg.SenderID[:8]
	}

	// Determine message type from attachment_url
	messageType := "text"
	if msg.AttachmentURL != nil && *msg.AttachmentURL != "" {
		// Check file extension
		url := *msg.AttachmentURL
		ext := strings.ToLower(filepath.Ext(url))
		switch ext {
		case ".jpg", ".jpeg", ".png", ".gif", ".webp":
			messageType = "image"
		case ".mp3", ".wav", ".m4a", ".aac", ".ogg":
			messageType = "audio"
		default:
			messageType = "file"
		}
	}

	response := gin.H{
		"id":              msg.ID,
		"conversation_id": msg.ConversationID,
		"sender_id":       msg.SenderID,
		"sender_name":     senderName,
		"content":         msg.Content,
		"type":            messageType,
		"timestamp":       msg.CreatedAt.Format("2006-01-02T15:04:05.000Z"),
		"is_read":         msg.IsRead,
	}

	if msg.AttachmentURL != nil {
		response["file_url"] = *msg.AttachmentURL
		response["attachment_url"] = *msg.AttachmentURL // Keep for backward compatibility
	}

	if msg.Sender != nil && msg.Sender.ProfileImageURL != nil {
		response["sender_avatar_url"] = *msg.Sender.ProfileImageURL
	}

	return response
}

type ChatHandler struct {
	conversationRepo ConversationRepositoryInterface
	messageRepo      MessageRepositoryInterface
}

func NewChatHandler(conversationRepo ConversationRepositoryInterface, messageRepo MessageRepositoryInterface) *ChatHandler {
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

	// Return paginated format expected by Flutter frontend
	c.JSON(http.StatusOK, PaginatedResponse(conversations, 1, len(conversations), len(conversations)))
}

func (h *ChatHandler) GetMessages(c *gin.Context) {
	conversationID := c.Param("id")
	page, pageSize := ParsePagination(c)

	messages, err := h.messageRepo.GetByConversationID(conversationID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Transform messages to Flutter-compatible format
	transformedMessages := make([]gin.H, len(messages))
	for i, msg := range messages {
		transformedMessages[i] = MessageResponse(&msg)
	}

	c.JSON(http.StatusOK, PaginatedResponse(transformedMessages, page, pageSize, len(transformedMessages)))
}

func (h *ChatHandler) SendMessage(c *gin.Context) {
	senderID := c.GetString("user_id")
	senderRole := c.GetString("role")
	conversationID := c.Param("id")

	var content string
	var attachmentURL *string
	var messageType string

	// Check if this is a multipart form (file upload) or JSON
	contentType := c.GetHeader("Content-Type")
	// Also check if file is present in form (some clients don't set Content-Type correctly)
	_, hasFileErr := c.FormFile("file")
	hasFile := hasFileErr == nil
	if strings.Contains(contentType, "multipart/form-data") || hasFile {
		// Handle file upload
		file, err := c.FormFile("file")
		if err == nil && file != nil {
			// File was uploaded, save it
			uploadDir := "./uploads"
			if err := os.MkdirAll(uploadDir, 0755); err != nil {
				c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to create upload directory"))
				return
			}

			// Generate unique filename
			ext := filepath.Ext(file.Filename)
			filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
			filepath := fmt.Sprintf("%s/%s", uploadDir, filename)

			// Save file
			if err := c.SaveUploadedFile(file, filepath); err != nil {
				c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to save file"))
				return
			}

			// Log file upload for debugging
			fmt.Printf("📤 [UPLOAD] File saved: %s, size: %d bytes\n", filepath, file.Size)

			url := fmt.Sprintf("/uploads/%s", filename)
			attachmentURL = &url

			// Determine message type from form data or file extension
			messageType = c.PostForm("type")
			if messageType == "" {
				extLower := strings.ToLower(ext)
				if extLower == ".jpg" || extLower == ".jpeg" || extLower == ".png" || extLower == ".gif" {
					messageType = "image"
				} else if extLower == ".mp3" || extLower == ".wav" || extLower == ".m4a" || extLower == ".aac" {
					messageType = "audio"
				} else {
					messageType = "file"
				}
			}

			// Content can be optional for file messages
			content = c.PostForm("content")
			if content == "" {
				content = file.Filename
			}
		} else {
			// No file, but multipart form - get content from form
			content = c.PostForm("content")
			if content == "" {
				c.JSON(http.StatusBadRequest, ErrorResponse("content is required"))
				return
			}
			messageType = c.PostForm("type")
			if messageType == "" {
				messageType = "text"
			}
		}
	} else {
		// Handle JSON request
		var req struct {
			Content       string  `json:"content" binding:"required"`
			AttachmentURL *string `json:"attachment_url"`
			Type          string  `json:"type"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, ErrorResponse(err.Error()))
			return
		}

		content = req.Content
		attachmentURL = req.AttachmentURL
		messageType = req.Type
		if messageType == "" {
			messageType = "text"
		}
	}

	// Get conversation by ID from URL path
	var conversation *models.Conversation
	var err error

	if conversationID != "" {
		// Try to get existing conversation by ID
		conversation, err = h.conversationRepo.GetByID(conversationID)
		if err != nil || conversation == nil {
			// If conversation not found, try to get or create one based on role
			if senderRole == "consumer" {
				supplierID := c.Query("supplier_id")
				if supplierID == "" {
					c.JSON(http.StatusBadRequest, ErrorResponse("Conversation not found and supplier_id required for new conversation"))
					return
				}
				conversation, err = h.conversationRepo.GetOrCreate(senderID, supplierID)
			} else {
				consumerID := c.Query("consumer_id")
				if consumerID == "" {
					c.JSON(http.StatusBadRequest, ErrorResponse("Conversation not found and consumer_id required for new conversation"))
					return
				}
				conversation, err = h.conversationRepo.GetOrCreate(consumerID, c.GetString("supplier_id"))
			}
		}
	} else {
		// No conversation ID, must create new one
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
	}

	if err != nil || conversation == nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to get or create conversation"))
		return
	}

	message := &models.Message{
		ConversationID: conversation.ID,
		SenderID:       senderID,
		SenderRole:     senderRole,
		Content:        content,
		AttachmentURL:  attachmentURL,
		IsRead:         false,
	}

	if err := h.messageRepo.Create(message); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Update conversation last message time
	h.conversationRepo.UpdateLastMessage(conversation.ID)

	// Get the created message with sender info for response
	// Reload messages to get sender information
	messages, err := h.messageRepo.GetByConversationID(conversation.ID, 1, 100)
	if err == nil {
		// Find the message we just created (should be the first one since DESC order)
		for _, m := range messages {
			if m.ID == message.ID {
				c.JSON(http.StatusCreated, SuccessResponse(MessageResponse(&m)))
				return
			}
		}
	}

	// Fallback: return transformed message without sender info
	// This should rarely happen, but handle gracefully
	c.JSON(http.StatusCreated, SuccessResponse(MessageResponse(message)))
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

