'use client'

import { useEffect, useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { getCurrentUser, logout } from './api/auth'
import { useAuthStore } from './store/auth-store'
import { isAuthenticated } from '@/lib/utils/cookies'
import type { UserRole } from '@/types/auth'

interface AuthGuardProps {
  children: React.ReactNode
  allowedRoles?: UserRole[]
  redirectTo?: string
}

export function AuthGuard({ children, allowedRoles, redirectTo }: AuthGuardProps) {
  const router = useRouter()
  const { user, setUser } = useAuthStore()
  const [isChecking, setIsChecking] = useState(true)
  const hasCheckedRef = useRef(false)
  const hasRedirectedRef = useRef(false)

  useEffect(() => {
    // Don't check if already on login page to prevent loops
    if (typeof window !== 'undefined' && window.location.pathname === '/login') {
      setIsChecking(false)
      return
    }

    // Only check once
    if (hasCheckedRef.current || hasRedirectedRef.current) return
    hasCheckedRef.current = true

    const checkAuth = async () => {
      try {
        // First, check if auth cookie exists - if not, logout immediately
        if (!isAuthenticated()) {
          // Cookie was deleted, logout and redirect
          const { setUser } = useAuthStore.getState()
          setUser(null)
          await logout()
          if (!hasRedirectedRef.current) {
            hasRedirectedRef.current = true
            const redirect = redirectTo || '/login'
            if (typeof window === 'undefined' || window.location.pathname !== '/login') {
              router.replace(redirect)
            }
          }
          return
        }

        // If user is already in store, use it
        if (user) {
          // Double-check cookie still exists
          if (!isAuthenticated()) {
            // Cookie was deleted while user was in store, logout
            setUser(null)
            await logout()
            if (!hasRedirectedRef.current) {
              hasRedirectedRef.current = true
              router.replace(redirectTo || '/login')
            }
            return
          }

          // Check role if specified
          if (allowedRoles && allowedRoles.length > 0) {
            if (!allowedRoles.includes(user.role)) {
              if (!hasRedirectedRef.current) {
                hasRedirectedRef.current = true
                const redirectMap: Record<UserRole, string> = {
                  owner: '/owner/dashboard',
                  manager: '/manager/dashboard',
                  sales: '/sales/dashboard',
                }
                router.replace(redirectMap[user.role] || '/login')
                return
              }
            }
          }
          setIsChecking(false)
          return
        }

        const currentUser = await getCurrentUser()
        
        if (!currentUser) {
          if (!hasRedirectedRef.current) {
            hasRedirectedRef.current = true
            const redirect = redirectTo || '/login'
            // Don't redirect if already on login page
            if (typeof window === 'undefined' || window.location.pathname !== '/login') {
              router.replace(redirect)
            }
          }
          return
        }

        setUser(currentUser)

        // Check role if specified
        if (allowedRoles && allowedRoles.length > 0) {
          if (!allowedRoles.includes(currentUser.role)) {
            if (!hasRedirectedRef.current) {
              hasRedirectedRef.current = true
              const redirectMap: Record<UserRole, string> = {
                owner: '/owner/dashboard',
                manager: '/manager/dashboard',
                sales: '/sales/dashboard',
              }
              router.replace(redirectMap[currentUser.role] || '/login')
            }
            return
          }
        }

        setIsChecking(false)
      } catch (error) {
        if (!hasRedirectedRef.current) {
          hasRedirectedRef.current = true
          const redirect = redirectTo || '/login'
          // Don't redirect if already on login page
          if (typeof window === 'undefined' || window.location.pathname !== '/login') {
            router.replace(redirect)
          } else {
            setIsChecking(false)
          }
        }
      }
    }

    checkAuth()

    // Set up periodic cookie check to detect if cookie was deleted
    const cookieCheckInterval = setInterval(() => {
      if (!isAuthenticated() && user) {
        // Cookie was deleted, logout
        setUser(null)
        logout().then(() => {
          router.replace('/login')
        })
      }
    }, 2000) // Check every 2 seconds

    // Cleanup interval on unmount
    return () => {
      clearInterval(cookieCheckInterval)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []) // Only run once on mount

  if (isChecking) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-sm text-neutral-500">Loading...</div>
      </div>
    )
  }

  return <>{children}</>
}

