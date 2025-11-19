import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { login, logout, getCurrentUser } from '../../lib/api/auth'
import { transformUser } from '../../lib/utils/transform'

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
    it('should handle backend response with access_token (snake_case) and transform user', async () => {
      const mockUser = {
        id: 'user1',
        email: 'test@example.com',
        role: 'owner',
        first_name: 'John',
        last_name: 'Doe',
        created_at: '2024-01-01T00:00:00Z',
      }

      const mockResponse = {
        data: {
          access_token: 'test-access-token',
          refresh_token: 'test-refresh-token',
          user: mockUser,
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
      expect(result.user.firstName).toBe('John')
      expect(result.user.first_name).toBe('John')
      expect(localStorage.getItem('auth_token')).toBe('test-access-token')
      expect(mockClient.post).toHaveBeenCalledWith('/auth/login', {
        email: 'test@example.com',
        password: 'password123',
        role: 'owner',
      })
    })

    it('should handle different roles', async () => {
      const mockResponse = {
        data: {
          access_token: 'token',
          user: { id: 'user1', email: 'manager@example.com', role: 'manager' },
        },
      }

      const mockClient = {
        post: vi.fn().mockResolvedValue(mockResponse),
        interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      const result = await login({
        email: 'manager@example.com',
        password: 'password',
        role: 'manager',
      })

      expect(result.user.role).toBe('manager')
      expect(mockClient.post).toHaveBeenCalledWith('/auth/login', {
        email: 'manager@example.com',
        password: 'password',
        role: 'manager',
      })
    })

    it('should handle login errors', async () => {
      const mockClient = {
        post: vi.fn().mockRejectedValue({
          response: {
            data: {
              message: 'Invalid credentials',
            },
          },
        }),
        interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
      }
      mockedAxios.create.mockReturnValue(mockClient)

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

      const mockClient = {
        post: vi.fn().mockResolvedValue({ data: { success: true } }),
        interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      await logout()

      expect(localStorage.getItem('auth_token')).toBeNull()
      expect(mockClient.post).toHaveBeenCalledWith('/auth/logout')
    })

    it('should clear token even if logout API call fails', async () => {
      localStorage.setItem('auth_token', 'test-token')

      const mockClient = {
        post: vi.fn().mockRejectedValue(new Error('Network error')),
        interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      await logout()

      expect(localStorage.getItem('auth_token')).toBeNull()
    })
  })

  describe('getCurrentUser', () => {
    it('should fetch and transform current user', async () => {
      const mockUserData = {
            id: 'user1',
            email: 'test@example.com',
            role: 'owner',
        first_name: 'Jane',
        last_name: 'Smith',
        created_at: '2024-01-01T00:00:00Z',
      }

      const mockClient = {
        get: vi.fn().mockResolvedValue({ data: mockUserData }),
        interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      const user = await getCurrentUser('test-token')

      expect(user).not.toBeNull()
      expect(user?.email).toBe('test@example.com')
      expect(user?.firstName).toBe('Jane')
      expect(user?.first_name).toBe('Jane')
      expect(user?.lastName).toBe('Smith')
      expect(mockClient.get).toHaveBeenCalledWith('/auth/me')
    })

    it('should return null on error', async () => {
      const mockClient = {
        get: vi.fn().mockRejectedValue(new Error('Unauthorized')),
        interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
      }
      mockedAxios.create.mockReturnValue(mockClient)

      const user = await getCurrentUser('invalid-token')

      expect(user).toBeNull()
    })
  })
})

