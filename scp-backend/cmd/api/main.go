package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"
	"github.com/scp-platform/backend/internal/api"
	"github.com/scp-platform/backend/internal/api/handlers"
	"github.com/scp-platform/backend/internal/api/websocket"
	"github.com/scp-platform/backend/internal/config"
	"github.com/scp-platform/backend/internal/repository"
	"github.com/scp-platform/backend/internal/services"
	"github.com/scp-platform/backend/pkg/jwt"
)

func main() {
	// Load .env file if exists
	godotenv.Load()

	cfg := config.Load()

	// Initialize database
	db, err := repository.NewDatabase(
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.DBName,
		cfg.Database.SSLMode,
	)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repositories
	userRepo := repository.NewUserRepository(db.DB)
	supplierRepo := repository.NewSupplierRepository(db.DB)
	productRepo := repository.NewProductRepository(db.DB)
	orderRepo := repository.NewOrderRepository(db.DB)
	linkRepo := repository.NewConsumerLinkRepository(db.DB)
	complaintRepo := repository.NewComplaintRepository(db.DB)
	conversationRepo := repository.NewConversationRepository(db.DB)
	messageRepo := repository.NewMessageRepository(db.DB)

	// Initialize JWT service
	jwtService := jwt.NewJWTService(
		cfg.JWT.SecretKey,
		cfg.JWT.AccessExpiry,
		cfg.JWT.RefreshExpiry,
	)

	// Initialize services
	authService := services.NewAuthService(userRepo, jwtService)
	orderService := services.NewOrderService(orderRepo, productRepo, linkRepo)
	dashboardService := services.NewDashboardService(orderRepo, linkRepo, productRepo)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService, userRepo)
	productHandler := handlers.NewProductHandler(productRepo)
	orderHandler := handlers.NewOrderHandler(orderService, orderRepo)
	consumerHandler := handlers.NewConsumerHandler(supplierRepo, linkRepo, productRepo, orderService)
	complaintHandler := handlers.NewComplaintHandler(complaintRepo)
	chatHandler := handlers.NewChatHandler(conversationRepo, messageRepo)
	dashboardHandler := handlers.NewDashboardHandler(dashboardService)
	
	// Create uploads directory
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		log.Printf("Warning: Failed to create uploads directory: %v", err)
	}
	uploadHandler := handlers.NewUploadHandler(uploadDir)

	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()
	wsHandler := handlers.NewWebSocketHandler(wsHub)

	// Setup routes
	router := api.SetupRoutes(
		authHandler,
		productHandler,
		orderHandler,
		consumerHandler,
		complaintHandler,
		chatHandler,
		dashboardHandler,
		uploadHandler,
		wsHandler,
		jwtService,
		cfg.Server.CORSOrigins,
	)

	// Serve static files
	router.Static("/uploads", uploadDir)

	// Create HTTP server
	srv := &http.Server{
		Addr:         ":" + cfg.Server.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on port %s", cfg.Server.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal for graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

