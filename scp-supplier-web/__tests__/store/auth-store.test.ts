import { describe, it, expect, beforeEach, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useAuthStore } from '../../lib/store/auth-store'
import { getCurrentUser, logout as apiLogout } from '../../lib/api/auth'

vi.mock('../../lib/api/auth', () => ({
  getCurrentUser: vi.fn(),
  logout: vi.fn(),
}))

const mockedGetCurrentUser = getCurrentUser as any
const mockedLogout = apiLogout as any

describe('Auth Store', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    // Reset store to initial state
    useAuthStore.setState({
      user: null,
      isLoading: true,
      isAuthenticated: false,
    })
  })

  describe('setUser', () => {
    it('should set user and update auth state', () => {
      const { result } = renderHook(() => useAuthStore())

      const mockUser = {
        id: 'user1',
        email: 'test@example.com',
        role: 'owner' as const,
      }

      act(() => {
        result.current.setUser(mockUser)
      })

      expect(result.current.user).toEqual(mockUser)
      expect(result.current.isAuthenticated).toBe(true)
      expect(result.current.isLoading).toBe(false)
    })

    it('should clear user when set to null', () => {
      const { result } = renderHook(() => useAuthStore())

      act(() => {
        result.current.setUser({ id: 'user1', email: 'test@example.com', role: 'owner' })
      })

      expect(result.current.isAuthenticated).toBe(true)

      act(() => {
        result.current.setUser(null)
      })

      expect(result.current.user).toBeNull()
      expect(result.current.isAuthenticated).toBe(false)
    })
  })

  describe('loadUser', () => {
    it('should load user from API when token exists', async () => {
      const mockUser = {
        id: 'user1',
        email: 'test@example.com',
        role: 'manager' as const,
      }

      localStorage.setItem('auth_token', 'test-token')
      mockedGetCurrentUser.mockResolvedValue(mockUser)

      const { result } = renderHook(() => useAuthStore())

      await act(async () => {
        await result.current.loadUser()
      })

      expect(result.current.user).toEqual(mockUser)
      expect(result.current.isAuthenticated).toBe(true)
      expect(result.current.isLoading).toBe(false)
      expect(mockedGetCurrentUser).toHaveBeenCalledWith('test-token')
    })

    it('should set state to unauthenticated when no token', async () => {
      localStorage.removeItem('auth_token')

      const { result } = renderHook(() => useAuthStore())

      await act(async () => {
        await result.current.loadUser()
      })

      expect(result.current.user).toBeNull()
      expect(result.current.isAuthenticated).toBe(false)
      expect(result.current.isLoading).toBe(false)
      expect(mockedGetCurrentUser).not.toHaveBeenCalled()
    })

    it('should handle errors and clear token', async () => {
      localStorage.setItem('auth_token', 'invalid-token')
      mockedGetCurrentUser.mockRejectedValue(new Error('Unauthorized'))

      const { result } = renderHook(() => useAuthStore())

      await act(async () => {
        await result.current.loadUser()
      })

      expect(result.current.user).toBeNull()
      expect(result.current.isAuthenticated).toBe(false)
      expect(localStorage.getItem('auth_token')).toBeNull()
    })
  })

  describe('logout', () => {
    it('should logout and clear state', async () => {
      localStorage.setItem('auth_token', 'test-token')
      mockedLogout.mockResolvedValue(undefined)

      const { result } = renderHook(() => useAuthStore())

      act(() => {
        result.current.setUser({ id: 'user1', email: 'test@example.com', role: 'owner' })
      })

      await act(async () => {
        await result.current.logout()
      })

      expect(result.current.user).toBeNull()
      expect(result.current.isAuthenticated).toBe(false)
      expect(localStorage.getItem('auth_token')).toBeNull()
      expect(mockedLogout).toHaveBeenCalled()
    })

    it('should clear token even if logout API fails', async () => {
      localStorage.setItem('auth_token', 'test-token')
      mockedLogout.mockRejectedValue(new Error('Network error'))

      const { result } = renderHook(() => useAuthStore())

      await act(async () => {
        await result.current.logout()
      })

      expect(result.current.user).toBeNull()
      expect(localStorage.getItem('auth_token')).toBeNull()
    })
  })

  describe('hasPermission', () => {
    it('should return true for owner regardless of required roles', () => {
      const { result } = renderHook(() => useAuthStore())

      act(() => {
        result.current.setUser({ id: 'user1', email: 'owner@example.com', role: 'owner' })
      })

      expect(result.current.hasPermission(['manager'])).toBe(true)
      expect(result.current.hasPermission(['owner'])).toBe(true)
      expect(result.current.hasPermission(['sales_rep'])).toBe(true)
    })

    it('should return true if user role matches required roles', () => {
      const { result } = renderHook(() => useAuthStore())

      act(() => {
        result.current.setUser({ id: 'user1', email: 'manager@example.com', role: 'manager' })
      })

      expect(result.current.hasPermission(['manager'])).toBe(true)
      expect(result.current.hasPermission(['owner'])).toBe(false)
      expect(result.current.hasPermission(['manager', 'sales_rep'])).toBe(true)
    })

    it('should return true when no required roles specified', () => {
      const { result } = renderHook(() => useAuthStore())

      act(() => {
        result.current.setUser({ id: 'user1', email: 'test@example.com', role: 'manager' })
      })

      expect(result.current.hasPermission()).toBe(true)
      expect(result.current.hasPermission([])).toBe(true)
    })

    it('should return false when user is not authenticated', () => {
      const { result } = renderHook(() => useAuthStore())

      act(() => {
        result.current.setUser(null)
      })

      expect(result.current.hasPermission(['manager'])).toBe(false)
    })
  })
})

