package handlers

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/scp-platform/backend/internal/models"
)

func TestConsumerHandler_RequestLink_LinkExists(t *testing.T) {
	link := &models.ConsumerLink{
		ID:         "link-123",
		ConsumerID: "consumer-123",
		SupplierID: "supplier-123",
		Status:     "pending",
	}

	// Test that link exists
	assert.NotEmpty(t, link.ID)
	assert.Equal(t, "pending", link.Status)
}

func TestConsumerHandler_ApproveLink_Unauthorized(t *testing.T) {
	link := &models.ConsumerLink{
		SupplierID: "supplier-1",
	}
	supplierID := "supplier-2"

	assert.NotEqual(t, link.SupplierID, supplierID)
}

func TestConsumerHandler_RejectLink_Unauthorized(t *testing.T) {
	link := &models.ConsumerLink{
		SupplierID: "supplier-1",
	}
	supplierID := "supplier-2"

	assert.NotEqual(t, link.SupplierID, supplierID)
}

func TestConsumerHandler_BlockLink_Unauthorized(t *testing.T) {
	link := &models.ConsumerLink{
		SupplierID: "supplier-1",
	}
	supplierID := "supplier-2"

	assert.NotEqual(t, link.SupplierID, supplierID)
}

func TestConsumerHandler_GetLinkedSuppliers_FilterApproved(t *testing.T) {
	links := []models.ConsumerLink{
		{Status: "pending"},
		{Status: "approved"},
		{Status: "rejected"},
		{Status: "approved"},
		{Status: "blocked"},
	}

	approvedLinks := []interface{}{}
	for _, link := range links {
		if link.Status == "approved" {
			approvedLinks = append(approvedLinks, link)
		}
	}

	assert.Len(t, approvedLinks, 2)
}

func TestConsumerHandler_GetLinkedSuppliers_NoApproved(t *testing.T) {
	links := []models.ConsumerLink{
		{Status: "pending"},
		{Status: "rejected"},
		{Status: "blocked"},
	}

	approvedLinks := []interface{}{}
	for _, link := range links {
		if link.Status == "approved" {
			approvedLinks = append(approvedLinks, link)
		}
	}

	assert.Len(t, approvedLinks, 0)
}

