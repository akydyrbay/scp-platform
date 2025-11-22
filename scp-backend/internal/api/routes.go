package api

import (
	"github.com/gin-gonic/gin"
	"github.com/scp-platform/backend/internal/api/handlers"
	"github.com/scp-platform/backend/internal/api/middleware"
	"github.com/scp-platform/backend/pkg/jwt"
)

func SetupRoutes(
	authHandler *handlers.AuthHandler,
	productHandler *handlers.ProductHandler,
	orderHandler *handlers.OrderHandler,
	consumerHandler *handlers.ConsumerHandler,
	complaintHandler *handlers.ComplaintHandler,
	chatHandler *handlers.ChatHandler,
	notificationHandler *handlers.NotificationHandler,
	supplierHandler *handlers.SupplierHandler,
	jwtService *jwt.JWTService,
	corsOrigins []string,
) *gin.Engine {
	router := gin.Default()

	// Middleware
	router.Use(middleware.CORSMiddleware(corsOrigins))
	router.Use(middleware.LoggingMiddleware())
	router.Use(middleware.ErrorMiddleware())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Auth routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/signup", authHandler.Signup)
			auth.POST("/refresh", authHandler.RefreshToken)
			
			// Protected auth routes
			authProtected := auth.Group("")
			authProtected.Use(middleware.AuthMiddleware(jwtService))
			{
				authProtected.GET("/me", authHandler.GetCurrentUser)
				authProtected.POST("/logout", authHandler.Logout)
			}
		}

		// Consumer routes
		consumer := v1.Group("/consumer")
		consumer.Use(middleware.AuthMiddleware(jwtService))
		consumer.Use(middleware.RequireRole("consumer"))
		{
			consumer.GET("/suppliers", consumerHandler.GetSuppliers)
			consumer.GET("/suppliers/:id", consumerHandler.GetSupplier)
			consumer.POST("/suppliers/:id/link-request", consumerHandler.RequestLink)
			consumer.GET("/supplier-links", consumerHandler.GetSupplierLinks)
			consumer.GET("/link-requests", consumerHandler.GetLinkRequests)
			consumer.GET("/linked-suppliers", consumerHandler.GetLinkedSuppliers)
			consumer.GET("/products", productHandler.GetConsumerProducts)
			consumer.GET("/products/:id", productHandler.GetProduct)
			consumer.POST("/orders", orderHandler.CreateOrder)
			consumer.GET("/orders", orderHandler.GetOrders)
			consumer.GET("/orders/current", orderHandler.GetCurrentOrders)
			consumer.GET("/orders/:id", orderHandler.GetOrder)
			consumer.POST("/orders/:id/cancel", orderHandler.CancelOrder)
			consumer.GET("/conversations", chatHandler.GetConversations)
			consumer.POST("/conversations", chatHandler.CreateConversation)
			consumer.GET("/conversations/:id/messages", chatHandler.GetMessages)
			consumer.POST("/conversations/:id/messages", chatHandler.SendMessage)
			consumer.POST("/conversations/:id/messages/read", chatHandler.MarkMessagesAsRead)
			consumer.GET("/notifications", notificationHandler.GetNotifications)
			consumer.POST("/notifications/:id/read", notificationHandler.MarkAsRead)
			consumer.POST("/notifications/mark-all-read", notificationHandler.MarkAllAsRead)
		}

		// Supplier routes
		supplier := v1.Group("/supplier")
		supplier.Use(middleware.AuthMiddleware(jwtService))
		supplier.Use(middleware.RequireRole("owner", "manager", "sales_rep"))
		{
			// Supplier profile
			supplier.GET("/me", supplierHandler.GetCurrentSupplier)

			// Products
			supplier.GET("/products", productHandler.GetProducts)
			supplier.GET("/products/:id", productHandler.GetProduct)
			supplier.POST("/products", productHandler.CreateProduct)
			supplier.PUT("/products/:id", productHandler.UpdateProduct)
			supplier.DELETE("/products/:id", productHandler.DeleteProduct)

			// Orders
			supplier.GET("/orders", orderHandler.GetSupplierOrders)
			supplier.GET("/orders/:id", orderHandler.GetSupplierOrder)
			supplier.POST("/orders/:id/accept", orderHandler.AcceptOrder)
			supplier.POST("/orders/:id/reject", orderHandler.RejectOrder)

			// Consumer links
			supplier.GET("/consumer-links", consumerHandler.GetSupplierLinksForSupplier)
			supplier.POST("/consumer-links/:id/approve", consumerHandler.ApproveLink)
			supplier.POST("/consumer-links/:id/reject", consumerHandler.RejectLink)
			supplier.POST("/consumer-links/:id/block", consumerHandler.BlockLink)

			// Complaints
			supplier.POST("/complaints", complaintHandler.CreateComplaint)
			supplier.GET("/complaints", complaintHandler.GetComplaints)
			supplier.GET("/complaints/:id", complaintHandler.GetComplaint)
			supplier.POST("/complaints/:id/escalate", complaintHandler.EscalateComplaint)
			supplier.POST("/complaints/:id/resolve", complaintHandler.ResolveComplaint)

			// Conversations (for sales reps)
			supplier.GET("/conversations", chatHandler.GetConversations)
			supplier.GET("/conversations/:id/messages", chatHandler.GetMessages)
			supplier.POST("/conversations/:id/messages", chatHandler.SendMessage)
			supplier.POST("/conversations/:id/messages/read", chatHandler.MarkMessagesAsRead)

			// Notifications
			supplier.GET("/notifications", notificationHandler.GetNotifications)
			supplier.POST("/notifications/:id/read", notificationHandler.MarkAsRead)
			supplier.POST("/notifications/mark-all-read", notificationHandler.MarkAllAsRead)

			// User management (owner/manager only)
			users := supplier.Group("/users")
			users.Use(middleware.RequireRole("owner", "manager"))
			{
				users.POST("", authHandler.CreateUser)
				users.GET("", authHandler.GetUsers)
				users.DELETE("/:id", authHandler.DeleteUser)
			}
		}

	}

	return router
}

