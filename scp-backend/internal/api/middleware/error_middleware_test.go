package middleware

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestErrorMiddleware_NoErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := ErrorMiddleware()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)

	middleware(c)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestErrorMiddleware_WithError(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := ErrorMiddleware()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Error(gin.Error{
		Err:  fmt.Errorf("internal server error"),
		Type: gin.ErrorTypePublic,
	})

	middleware(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

func TestErrorMiddleware_MultipleErrors(t *testing.T) {
	gin.SetMode(gin.TestMode)

	middleware := ErrorMiddleware()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Error(gin.Error{Err: fmt.Errorf("invalid JSON")})
	c.Error(gin.Error{Err: fmt.Errorf("bind error")})

	middleware(c)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}

