'use client'

import { useEffect, useState, use, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store/auth-store'
import { getCurrentUser } from '@/lib/api/auth'
import { LoginForm } from '@/components/auth/login-form'

interface LoginPageProps {
  searchParams: Promise<{
    redirect?: string
  }>
}

export default function LoginPage({ searchParams }: LoginPageProps) {
  const router = useRouter()
  const { user, setUser } = useAuthStore()
  const params = use(searchParams)
  const [isChecking, setIsChecking] = useState(true)
  const hasCheckedRef = useRef(false)

  useEffect(() => {
    // Only check once
    if (hasCheckedRef.current) return

    // If user is already in store, redirect immediately
    if (user) {
      const redirectMap: Record<string, string> = {
        owner: '/owner/dashboard',
        manager: '/manager/dashboard',
        sales: '/sales/dashboard',
      }
      const redirectPath = redirectMap[user.role] || '/manager/dashboard'
      router.replace(params.redirect || redirectPath)
      return
    }

    // Check if user is already logged in
    const checkAuth = async () => {
      if (hasCheckedRef.current) return
      hasCheckedRef.current = true

      try {
        const currentUser = await getCurrentUser()
        if (currentUser) {
          setUser(currentUser)
          const redirectMap: Record<string, string> = {
            owner: '/owner/dashboard',
            manager: '/manager/dashboard',
            sales: '/sales/dashboard',
          }
          const redirectPath = redirectMap[currentUser.role] || '/manager/dashboard'
          router.replace(params.redirect || redirectPath)
          return
        }
      } catch (error) {// User not authenticated, continue to show login form
      } finally {
        setIsChecking(false)
      }
    }

    checkAuth()
  }, [])

  // Show loading state while checking authentication
  if (isChecking) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-50 via-white to-neutral-100">
        <div className="text-sm text-neutral-500">Loading...</div>
      </div>
    )
  }

  return <LoginForm redirectTo={params.redirect} />
}

