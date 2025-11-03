package handlers

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UploadHandler struct {
	uploadDir string
}

func NewUploadHandler(uploadDir string) *UploadHandler {
	return &UploadHandler{
		uploadDir: uploadDir,
	}
}

func (h *UploadHandler) UploadFile(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse("File is required"))
		return
	}

	// Validate file type
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowedExts := []string{".jpg", ".jpeg", ".png", ".gif", ".pdf"}
	allowed := false
	for _, allowedExt := range allowedExts {
		if ext == allowedExt {
			allowed = true
			break
		}
	}

	if !allowed {
		c.JSON(http.StatusBadRequest, ErrorResponse("Invalid file type. Allowed: jpg, jpeg, png, gif, pdf"))
		return
	}

	// Validate file size (10MB max)
	if file.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, ErrorResponse("File size exceeds 10MB"))
		return
	}

	// Generate unique filename
	filename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
	filepath := fmt.Sprintf("%s/%s", h.uploadDir, filename)

	// Save file
	if err := c.SaveUploadedFile(file, filepath); err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse("Failed to save file"))
		return
	}

	// Return URL
	url := fmt.Sprintf("/uploads/%s", filename)
	c.JSON(http.StatusOK, SuccessResponse(gin.H{"url": url}))
}

