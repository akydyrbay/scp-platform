package password

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHash(t *testing.T) {
	password := "test-password-123"
	hash, err := Hash(password)
	assert.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)
	assert.Len(t, hash, 60) // bcrypt hash length
}

func TestHash_DifferentPasswords(t *testing.T) {
	hash1, err1 := Hash("password1")
	hash2, err2 := Hash("password2")

	assert.NoError(t, err1)
	assert.NoError(t, err2)
	assert.NotEqual(t, hash1, hash2)
}

func TestHash_SamePassword_DifferentHashes(t *testing.T) {
	password := "same-password"
	hash1, err1 := Hash(password)
	hash2, err2 := Hash(password)

	assert.NoError(t, err1)
	assert.NoError(t, err2)
	// bcrypt generates different hashes each time due to salt
	assert.NotEqual(t, hash1, hash2)
}

func TestVerify(t *testing.T) {
	password := "test-password-123"
	hash, err := Hash(password)
	assert.NoError(t, err)

	valid := Verify(password, hash)
	assert.True(t, valid)
}

func TestVerify_WrongPassword(t *testing.T) {
	password := "test-password-123"
	hash, err := Hash(password)
	assert.NoError(t, err)

	valid := Verify("wrong-password", hash)
	assert.False(t, valid)
}

func TestVerify_InvalidHash(t *testing.T) {
	valid := Verify("password", "invalid-hash")
	assert.False(t, valid)
}

func TestHash_EmptyPassword(t *testing.T) {
	hash, err := Hash("")
	assert.NoError(t, err)
	assert.NotEmpty(t, hash)

	valid := Verify("", hash)
	assert.True(t, valid)
}

func TestHash_LongPassword(t *testing.T) {
	// bcrypt has a 72 byte limit, so test with 70 bytes
	longPassword := make([]byte, 70)
	for i := range longPassword {
		longPassword[i] = 'a'
	}

	hash, err := Hash(string(longPassword))
	assert.NoError(t, err)
	assert.NotEmpty(t, hash)

	valid := Verify(string(longPassword), hash)
	assert.True(t, valid)
}

