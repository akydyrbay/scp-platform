package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestCORSMiddleware_AllowedOrigin(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := CORSMiddleware([]string{"http://localhost:3000", "https://example.com"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Origin", "http://localhost:3000")

	middleware(c)

	assert.Equal(t, "http://localhost:3000", w.Header().Get("Access-Control-Allow-Origin"))
	assert.Equal(t, "true", w.Header().Get("Access-Control-Allow-Credentials"))
}

func TestCORSMiddleware_WildcardOrigin(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := CORSMiddleware([]string{"*"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Origin", "http://any-origin.com")

	middleware(c)

	assert.Equal(t, "http://any-origin.com", w.Header().Get("Access-Control-Allow-Origin"))
}

func TestCORSMiddleware_NotAllowedOrigin(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := CORSMiddleware([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Origin", "http://malicious.com")

	middleware(c)

	assert.Empty(t, w.Header().Get("Access-Control-Allow-Origin"))
}

func TestCORSMiddleware_OptionsRequest(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := CORSMiddleware([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("OPTIONS", "/test", nil)
	c.Request.Header.Set("Origin", "http://localhost:3000")

	middleware(c)

	assert.Equal(t, http.StatusNoContent, w.Code)
}

func TestCORSMiddleware_Headers(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := CORSMiddleware([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Request.Header.Set("Origin", "http://localhost:3000")

	middleware(c)

	assert.Contains(t, w.Header().Get("Access-Control-Allow-Headers"), "Authorization")
	assert.Contains(t, w.Header().Get("Access-Control-Allow-Methods"), "GET")
	assert.Contains(t, w.Header().Get("Access-Control-Allow-Methods"), "POST")
}

func TestCORSMiddleware_NoOrigin(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := CORSMiddleware([]string{"http://localhost:3000"})

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)

	middleware(c)

	assert.Empty(t, w.Header().Get("Access-Control-Allow-Origin"))
}

