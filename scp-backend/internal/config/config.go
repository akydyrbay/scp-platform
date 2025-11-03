package config

import (
	"os"
	"strconv"
	"strings"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Redis    RedisConfig
	Storage  StorageConfig
}

type ServerConfig struct {
	Port        string
	Environment string
	CORSOrigins []string
}

type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type JWTConfig struct {
	SecretKey     string
	AccessExpiry  int // minutes
	RefreshExpiry int // days
}

type RedisConfig struct {
	Host     string
	Port     int
	Password string
}

type StorageConfig struct {
	Type      string // local or s3
	S3Bucket  string
	AWSRegion string
}

func Load() *Config {
	corsOrigins := getEnv("CORS_ORIGINS", "http://localhost:3000,http://localhost:3001,http://localhost:8080")
	
	return &Config{
		Server: ServerConfig{
			Port:        getEnv("PORT", "3000"),
			Environment: getEnv("ENV", "development"),
			CORSOrigins: strings.Split(corsOrigins, ","),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getIntEnv("DB_PORT", 5432),
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", "postgres"),
			DBName:   getEnv("DB_NAME", "scp_platform"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		JWT: JWTConfig{
			SecretKey:     getEnv("JWT_SECRET", "change-me-in-production"),
			AccessExpiry:  getIntEnv("JWT_ACCESS_EXPIRY", 15),
			RefreshExpiry: getIntEnv("JWT_REFRESH_EXPIRY", 7),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getIntEnv("REDIS_PORT", 6379),
			Password: getEnv("REDIS_PASSWORD", ""),
		},
		Storage: StorageConfig{
			Type:      getEnv("STORAGE_TYPE", "local"),
			S3Bucket:  getEnv("S3_BUCKET", ""),
			AWSRegion: getEnv("AWS_REGION", "us-east-1"),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

