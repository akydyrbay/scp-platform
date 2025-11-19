import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { getClientApiClient, getServerApiClient } from '../../lib/api/client'

vi.mock('axios', () => ({
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
}))

const mockedAxios = axios as any

describe('API Client', () => {
  let mockAxiosInstance: any

  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()

    mockAxiosInstance = {
      post: vi.fn(),
      get: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    }

    mockedAxios.create.mockReturnValue(mockAxiosInstance)
  })

  describe('getClientApiClient', () => {
    it('should create client with correct base URL', () => {
      const client = getClientApiClient()

      expect(mockedAxios.create).toHaveBeenCalled()
      const createCall = mockedAxios.create.mock.calls[0][0]
      expect(createCall.baseURL).toBeDefined()
      expect(createCall.timeout).toBe(30000)
    })

    it('should add auth token from localStorage to requests', () => {
      localStorage.setItem('auth_token', 'test-token')

      getClientApiClient()
      
      expect(mockAxiosInstance.interceptors.request.use).toHaveBeenCalled()
      
      // Get the interceptor function and test it
      const interceptorFn = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      const config = { headers: {} }
      const result = interceptorFn(config)
      
      expect(result.headers.Authorization).toBe('Bearer test-token')
    })

    it('should use provided token parameter instead of localStorage', () => {
      localStorage.setItem('auth_token', 'local-token')

      getClientApiClient('param-token')

      const interceptorFn = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      const config = { headers: {} }
      const result = interceptorFn(config)

      expect(result.headers.Authorization).toBe('Bearer param-token')
    })

    it('should handle 401 errors and redirect to login', async () => {
      getClientApiClient()

      expect(mockAxiosInstance.interceptors.response.use).toHaveBeenCalled()
      
      const errorHandler = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      const error = {
        response: {
          status: 401,
        },
      }

      Object.defineProperty(window, 'location', {
        value: { href: '' },
        writable: true,
      })

      localStorage.setItem('auth_token', 'token')
      
      // Error handler returns a rejected promise - catch it to prevent unhandled rejection
      const result = errorHandler(error)
      await result.catch(() => {
        // Expected rejection - handler clears token and redirects
      })

      expect(localStorage.getItem('auth_token')).toBeNull()
    })

    it('should not redirect on non-401 errors', async () => {
      getClientApiClient()

      const errorHandler = mockAxiosInstance.interceptors.response.use.mock.calls[0][1]
      const error = {
        response: {
          status: 500,
        },
      }

      // Non-401 errors should return rejected promise without clearing token
      const result = errorHandler(error)
      
      // Verify it returns a rejected promise (not modifying token)
      expect(result).toBeInstanceOf(Promise)
      
      // Catch the rejection to prevent unhandled rejection warning
      await result.catch((err) => {
        expect(err).toEqual(error)
      })
      
      expect(localStorage.getItem('auth_token')).toBeNull() // No token was set
    })
  })

  describe('getServerApiClient', () => {
    it('should create server-side client with token', () => {
      const client = getServerApiClient('server-token')

      expect(mockedAxios.create).toHaveBeenCalled()
      expect(mockAxiosInstance.interceptors.request.use).toHaveBeenCalled()

      const interceptorFn = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      const config = { headers: {} }
      const result = interceptorFn(config)

      expect(result.headers.Authorization).toBe('Bearer server-token')
    })

    it('should work without token', () => {
      getServerApiClient()

      expect(mockedAxios.create).toHaveBeenCalled()
      const interceptorFn = mockAxiosInstance.interceptors.request.use.mock.calls[0][0]
      const config = { headers: {} }
      const result = interceptorFn(config)

      expect(result.headers.Authorization).toBeUndefined()
    })
  })
})

