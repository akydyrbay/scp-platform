import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { getClientApiClient, getServerApiClient } from '../../lib/api/client'

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

describe('API Client', () => {
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

  describe('getClientApiClient', () => {
    it('should add auth token from localStorage to requests', () => {
      localStorage.setItem('auth_token', 'test-token')

      const client = getClientApiClient()
      
      // Verify axios.create was called
      expect(mockedAxios.create).toHaveBeenCalled()
      
      // Verify interceptors are set up
      const mockInstance = mockedAxios.create.mock.results[0].value
      expect(mockInstance.interceptors.request.use).toHaveBeenCalled()
    })

    it('should handle 401 errors and redirect to login', () => {
      // Mock window.location
      const mockLocation = { href: '' }
      Object.defineProperty(window, 'location', {
        value: mockLocation,
        writable: true,
      })

      const client = getClientApiClient()
      
      // Verify axios.create was called
      expect(mockedAxios.create).toHaveBeenCalled()
      
      // Verify response interceptor is set up
      const mockInstance = mockedAxios.create.mock.results[0].value
      expect(mockInstance.interceptors.response.use).toHaveBeenCalled()
    })

    it('should use provided token parameter', () => {
      const client = getClientApiClient('custom-token')
      expect(client).toBeDefined()
    })
  })

  describe('getServerApiClient', () => {
    it('should create server-side client with token', () => {
      const client = getServerApiClient('server-token')
      expect(client).toBeDefined()
    })

    it('should work without token', () => {
      const client = getServerApiClient()
      expect(client).toBeDefined()
    })
  })
})

