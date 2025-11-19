'use client'

import { create } from 'zustand'
import type { User, UserRole } from '../types'
import { getCurrentUser, logout as apiLogout } from '../api/auth'

interface AuthState {
  user: User | null
  isLoading: boolean
  isAuthenticated: boolean
  setUser: (user: User | null) => void
  loadUser: () => Promise<void>
  logout: () => Promise<void>
  hasPermission: (requiredRoles?: UserRole[]) => boolean
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  isLoading: true,
  isAuthenticated: false,

  setUser: (user) => {
    set({
      user,
      isAuthenticated: !!user,
      isLoading: false,
    })
  },

  loadUser: async () => {
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
      if (!token) {
        set({ isLoading: false, isAuthenticated: false, user: null })
        return
      }

      const user = await getCurrentUser(token)
      set({
        user,
        isAuthenticated: !!user,
        isLoading: false,
      })
    } catch (error) {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('auth_token')
      }
      set({ isLoading: false, isAuthenticated: false, user: null })
    }
  },

  logout: async () => {
    try {
    await apiLogout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('auth_token')
      }
    set({
      user: null,
      isAuthenticated: false,
    })
    }
  },

  hasPermission: (requiredRoles?: UserRole[]) => {
    const { user } = get()
    
    // If no required roles specified, allow access
    if (!requiredRoles || requiredRoles.length === 0) return true
    
    // If no user, deny access when roles are required
    if (!user) return false

    // Owner has all permissions
    if (user.role === 'owner') return true

    // Check if user role is in required roles
    return requiredRoles.includes(user.role)
  },
}))

