package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/repository"
)

type NotificationHandler struct {
	notificationRepo *repository.NotificationRepository
}

func NewNotificationHandler(notificationRepo *repository.NotificationRepository) *NotificationHandler {
	return &NotificationHandler{
		notificationRepo: notificationRepo,
	}
}

func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userID := c.GetString("user_id")
	page, pageSize := ParsePagination(c)

	// Check for unread_only query parameter
	unreadOnly := false
	if unreadOnlyStr := c.Query("unread_only"); unreadOnlyStr != "" {
		unreadOnly, _ = strconv.ParseBool(unreadOnlyStr)
	}

	notifications, total, err := h.notificationRepo.GetByUserID(userID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	// Filter unread if requested
	if unreadOnly {
		var unreadNotifications []interface{}
		for _, n := range notifications {
			if !n.IsRead {
				unreadNotifications = append(unreadNotifications, n)
			}
		}
		c.JSON(http.StatusOK, PaginatedResponse(unreadNotifications, page, pageSize, len(unreadNotifications)))
		return
	}

	c.JSON(http.StatusOK, PaginatedResponse(notifications, page, pageSize, total))
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	notificationID := c.Param("id")
	userID := c.GetString("user_id")

	// Verify notification belongs to user (optional security check)
	notifications, _, err := h.notificationRepo.GetByUserID(userID, 1, 1000)
	if err == nil {
		found := false
		for _, n := range notifications {
			if n.ID == notificationID {
				found = true
				break
			}
		}
		if !found {
			c.JSON(http.StatusNotFound, ErrorResponse("Notification not found"))
			return
		}
	}

	if err := h.notificationRepo.MarkAsRead(notificationID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(gin.H{"message": "Notification marked as read"}))
}

func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	userID := c.GetString("user_id")

	if err := h.notificationRepo.MarkAllAsRead(userID); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse(err.Error()))
		return
	}

	c.JSON(http.StatusOK, SuccessResponse(gin.H{"message": "All notifications marked as read"}))
}

