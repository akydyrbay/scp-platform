import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { login, logout, getCurrentUser } from '../../lib/api/auth'

// Mock localStorage for Node.js environment
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value.toString()
    },
    removeItem: (key: string) => {
      delete store[key]
    },
    clear: () => {
      store = {}
    },
  }
})()

// Define global window and localStorage if not available (Node.js environment)
if (typeof window === 'undefined') {
  ;(global as any).window = {
    localStorage: localStorageMock,
  }
} else {
  Object.defineProperty(window, 'localStorage', {
    value: localStorageMock,
    writable: true,
  })
}

// Also define localStorage directly on global for direct access
;(global as any).localStorage = localStorageMock

// Mock axios
vi.mock('axios', () => {
  return {
    default: {
      create: vi.fn(() => ({
        post: vi.fn(),
        get: vi.fn(),
        interceptors: {
          request: { use: vi.fn() },
          response: { use: vi.fn() },
        },
      })),
    },
  }
})

const mockedAxios = axios as any

describe('Auth API', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    // Reset axios.create to return a fresh instance each time
    mockedAxios.create.mockImplementation(() => ({
      post: vi.fn(),
      get: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    }))
  })

  describe('login', () => {
    it('should handle backend response with access_token (snake_case)', async () => {
      const mockResponse = {
        data: {
          access_token: 'test-access-token',
          refresh_token: 'test-refresh-token',
          user: {
            id: 'user1',
            email: 'test@example.com',
            role: 'owner',
          },
        },
      }

      const mockClient = {
        post: vi.fn().mockResolvedValue(mockResponse),
        interceptors: {
          request: { use: vi.fn() },
          response: { use: vi.fn() },
        },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      const result = await login({
        email: 'test@example.com',
        password: 'password123',
      })

      expect(result.accessToken).toBe('test-access-token')
      expect(result.refreshToken).toBe('test-refresh-token')
      expect(result.user.email).toBe('test@example.com')
      expect(localStorage.getItem('auth_token')).toBe('test-access-token')
    })

    it('should handle backend response with accessToken (camelCase)', async () => {
      const mockResponse = {
        data: {
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          user: {
            id: 'user1',
            email: 'test@example.com',
            role: 'owner',
          },
        },
      }

      const mockClient = {
        post: vi.fn().mockResolvedValue(mockResponse),
        interceptors: {
          request: { use: vi.fn() },
          response: { use: vi.fn() },
        },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      const result = await login({
        email: 'test@example.com',
        password: 'password123',
      })

      expect(result.accessToken).toBe('test-access-token')
      expect(result.refreshToken).toBe('test-refresh-token')
      expect(result.user.email).toBe('test@example.com')
    })

    it('should handle login errors', async () => {
      mockedAxios.create.mockReturnValue({
        post: vi.fn().mockRejectedValue({
          response: {
            data: {
              message: 'Invalid credentials',
            },
          },
        }),
      })

      await expect(
        login({
          email: 'test@example.com',
          password: 'wrongpassword',
        })
      ).rejects.toThrow()
    })
  })

  describe('logout', () => {
    it('should clear auth token from localStorage', async () => {
      localStorage.setItem('auth_token', 'test-token')

      // Get the mock client instance and set up the post method
      const mockClient = mockedAxios.create()
      mockClient.post.mockResolvedValue({})

      await logout()

      expect(localStorage.getItem('auth_token')).toBeNull()
    })
  })

  describe('getCurrentUser', () => {
    it('should fetch current user with token', async () => {
      const mockResponse = {
        data: {
          user: {
            id: 'user1',
            email: 'test@example.com',
            role: 'owner',
          },
        },
      }

      const mockClient = {
        get: vi.fn().mockResolvedValue(mockResponse),
        interceptors: {
          request: { use: vi.fn() },
          response: { use: vi.fn() },
        },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      const user = await getCurrentUser('test-token')

      expect(user).not.toBeNull()
      expect(user?.email).toBe('test@example.com')
    })

    it('should return null on error', async () => {
      mockedAxios.create.mockReturnValue({
        get: vi.fn().mockRejectedValue(new Error('Unauthorized')),
      })

      const user = await getCurrentUser('invalid-token')

      expect(user).toBeNull()
    })
  })
})

