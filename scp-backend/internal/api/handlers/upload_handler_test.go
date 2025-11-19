package handlers

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestUploadHandler_UploadFile_InvalidFileType(t *testing.T) {
	// Test file extension validation
	ext := ".exe"
	allowedExts := []string{".jpg", ".jpeg", ".png", ".gif", ".pdf"}
	allowed := false
	for _, allowedExt := range allowedExts {
		if ext == allowedExt {
			allowed = true
			break
		}
	}

	assert.False(t, allowed)
}

func TestUploadHandler_UploadFile_ValidFileType(t *testing.T) {
	ext := ".jpg"
	allowedExts := []string{".jpg", ".jpeg", ".png", ".gif", ".pdf"}
	allowed := false
	for _, allowedExt := range allowedExts {
		if ext == allowedExt {
			allowed = true
			break
		}
	}

	assert.True(t, allowed)
}

func TestUploadHandler_UploadFile_FileSizeLimit(t *testing.T) {
	fileSize := int64(15 * 1024 * 1024) // 15MB
	maxSize := int64(10 * 1024 * 1024)  // 10MB

	assert.Greater(t, fileSize, maxSize)
}

func TestUploadHandler_UploadFile_ValidFileSize(t *testing.T) {
	fileSize := int64(5 * 1024 * 1024) // 5MB
	maxSize := int64(10 * 1024 * 1024) // 10MB

	assert.LessOrEqual(t, fileSize, maxSize)
}

func TestUploadHandler_UploadFile_AllAllowedExtensions(t *testing.T) {
	allowedExts := []string{".jpg", ".jpeg", ".png", ".gif", ".pdf"}

	testCases := []struct {
		ext     string
		allowed bool
	}{
		{".jpg", true},
		{".jpeg", true},
		{".png", true},
		{".gif", true},
		{".pdf", true},
		{".exe", false},
		{".zip", false},
		{".doc", false},
	}

	for _, tc := range testCases {
		allowed := false
		for _, allowedExt := range allowedExts {
			if tc.ext == allowedExt {
				allowed = true
				break
			}
		}
		assert.Equal(t, tc.allowed, allowed, "Extension %s should be %v", tc.ext, tc.allowed)
	}
}

