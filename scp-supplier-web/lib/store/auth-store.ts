'use client'

import { create } from 'zustand'
import type { User } from '../types'
import { getCurrentUser, logout as apiLogout } from '../api/auth'

interface AuthState {
  user: User | null
  isLoading: boolean
  isAuthenticated: boolean
  setUser: (user: User | null) => void
  loadUser: () => Promise<void>
  logout: () => Promise<void>
  hasPermission: (requiredRole?: 'owner' | 'manager') => boolean
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
        set({ isLoading: false, isAuthenticated: false })
        return
      }

      const user = await getCurrentUser(token)
      set({
        user,
        isAuthenticated: !!user,
        isLoading: false,
      })
    } catch (error) {
      set({ isLoading: false, isAuthenticated: false })
    }
  },

  logout: async () => {
    await apiLogout()
    set({
      user: null,
      isAuthenticated: false,
    })
  },

  hasPermission: (requiredRole?: 'owner' | 'manager') => {
    const { user } = get()
    if (!user) return false

    // Owner has all permissions
    if (user.role === 'owner') return true

    // Manager has manager-level permissions
    if (requiredRole === 'manager' && user.role === 'manager') return true

    // Owner-only routes
    if (requiredRole === 'owner') return false

    return false
  },
}))

