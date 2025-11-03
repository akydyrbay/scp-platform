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
	dashboardHandler *handlers.DashboardHandler,
	uploadHandler *handlers.UploadHandler,
	wsHandler *handlers.WebSocketHandler,
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
			auth.POST("/refresh", authHandler.RefreshToken)
			
			// Protected auth routes
			authProtected := auth.Group("")
			authProtected.Use(middleware.AuthMiddleware(jwtService))
			{
				authProtected.GET("/me", authHandler.GetCurrentUser)
				authProtected.POST("/logout", authHandler.Logout)
			}
		}

		// Public supplier discovery (used by consumers)
		suppliers := v1.Group("/suppliers")
		suppliers.Use(middleware.AuthMiddleware(jwtService))
		suppliers.Use(middleware.RequireRole("consumer"))
		{
			suppliers.GET("/discover", consumerHandler.GetSuppliers)
			suppliers.GET("/:id", consumerHandler.GetSupplier)
			suppliers.POST("/:id/link-request", consumerHandler.RequestLink)
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
			consumer.GET("/link-requests", consumerHandler.GetSupplierLinks)
			consumer.GET("/linked-suppliers", consumerHandler.GetLinkedSuppliers)
			consumer.GET("/products", productHandler.GetConsumerProducts)
			consumer.GET("/products/:id", productHandler.GetProduct)
			consumer.POST("/orders", orderHandler.CreateOrder)
			consumer.GET("/orders", orderHandler.GetOrders)
			consumer.GET("/orders/current", orderHandler.GetCurrentOrders)
			consumer.GET("/orders/:id", orderHandler.GetOrder)
			consumer.GET("/orders/:id/track", orderHandler.GetOrder)
			consumer.POST("/orders/:id/cancel", orderHandler.CancelOrder)
			consumer.GET("/conversations", chatHandler.GetConversations)
			consumer.GET("/conversations/:id/messages", chatHandler.GetMessages)
			consumer.POST("/conversations/:id/messages", chatHandler.SendMessage)
			consumer.POST("/conversations/:id/messages/read", chatHandler.MarkMessagesAsRead)
		}

		// Supplier routes
		supplier := v1.Group("/supplier")
		supplier.Use(middleware.AuthMiddleware(jwtService))
		supplier.Use(middleware.RequireRole("owner", "manager", "sales_rep"))
		{
			// Products
			supplier.GET("/products", productHandler.GetProducts)
			supplier.POST("/products", productHandler.CreateProduct)
			supplier.PUT("/products/:id", productHandler.UpdateProduct)
			supplier.DELETE("/products/:id", productHandler.DeleteProduct)
			supplier.POST("/products/bulk-update", productHandler.BulkUpdateProducts)

			// Orders
			supplier.GET("/orders", orderHandler.GetSupplierOrders)
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
			supplier.POST("/complaints/:id/escalate", complaintHandler.EscalateComplaint)
			supplier.POST("/complaints/:id/resolve", complaintHandler.ResolveComplaint)

			// Conversations (for sales reps)
			supplier.GET("/conversations", chatHandler.GetConversations)
			supplier.GET("/conversations/:id/messages", chatHandler.GetMessages)
			supplier.POST("/conversations/:id/messages", chatHandler.SendMessage)
			supplier.POST("/conversations/:id/messages/read", chatHandler.MarkMessagesAsRead)

			// Dashboard
			supplier.GET("/dashboard/stats", dashboardHandler.GetStats)

			// User management (owner/manager only)
			users := supplier.Group("/users")
			users.Use(middleware.RequireRole("owner", "manager"))
			{
				users.POST("", authHandler.CreateUser)
				users.GET("", authHandler.GetUsers)
				users.DELETE("/:id", authHandler.DeleteUser)
			}
		}

		// Upload
		upload := v1.Group("/upload")
		upload.Use(middleware.AuthMiddleware(jwtService))
		{
			upload.POST("", uploadHandler.UploadFile)
		}

		// WebSocket
		ws := v1.Group("/ws")
		ws.Use(middleware.AuthMiddleware(jwtService))
		{
			ws.GET("", wsHandler.HandleWebSocket)
		}
	}

	return router
}

