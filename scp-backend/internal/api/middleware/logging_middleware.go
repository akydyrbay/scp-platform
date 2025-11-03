package middleware

import (
	"encoding/json"
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

var (
	logFileHandle *os.File
	logFileMutex  sync.Mutex
)

type LogEntry struct {
	Timestamp    string `json:"timestamp"`
	Level        string `json:"level"`
	Method       string `json:"method"`
	Path         string `json:"path"`
	Status       int    `json:"status"`
	Latency      string `json:"latency"`
	ClientIP     string `json:"client_ip"`
	UserAgent    string `json:"user_agent"`
	ErrorMessage string `json:"error_message,omitempty"`
}

func init() {
	logFile := os.Getenv("LOG_FILE")
	if logFile != "" {
		var err error
		logFileHandle, err = os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Failed to open log file %s: %v\n", logFile, err)
		}
	}
}

func LoggingMiddleware() gin.HandlerFunc {
	logFormat := os.Getenv("LOG_FORMAT")

	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		timestamp := param.TimeStamp.Format(time.RFC3339)
		var logLine string

		if logFormat == "json" {
			entry := LogEntry{
				Timestamp: timestamp,
				Level:     getLogLevel(param.StatusCode),
				Method:    param.Method,
				Path:      param.Path,
				Status:    param.StatusCode,
				Latency:   param.Latency.String(),
				ClientIP:  param.ClientIP,
				UserAgent: param.Request.UserAgent(),
			}

			if param.ErrorMessage != "" {
				entry.ErrorMessage = param.ErrorMessage
			}

			jsonBytes, err := json.Marshal(entry)
			if err == nil {
				logLine = string(jsonBytes) + "\n"
			} else {
				// Fallback to text format if JSON marshaling fails
				logLine = fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
					param.ClientIP,
					timestamp,
					param.Method,
					param.Path,
					param.Request.Proto,
					param.StatusCode,
					param.Latency,
					param.Request.UserAgent(),
					param.ErrorMessage,
				)
			}
		} else {
			// Default text format
			logLine = fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
				param.ClientIP,
				timestamp,
				param.Method,
				param.Path,
				param.Request.Proto,
				param.StatusCode,
				param.Latency,
				param.Request.UserAgent(),
				param.ErrorMessage,
			)
		}

		// Write to file if configured
		if logFileHandle != nil {
			logFileMutex.Lock()
			logFileHandle.WriteString(logLine)
			logFileMutex.Unlock()
		}

		return logLine
	})
}

func getLogLevel(statusCode int) string {
	if statusCode >= 500 {
		return "error"
	} else if statusCode >= 400 {
		return "warn"
	}
	return "info"
}
