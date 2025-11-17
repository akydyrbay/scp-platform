import { getClientApiClient } from './client'
import type { User } from '../types'

export interface LoginCredentials {
  email: string
  password: string
  role?: 'supplier'
}

export interface LoginResponse {
  accessToken: string
  refreshToken?: string
  user: User
}

export async function login(credentials: LoginCredentials): Promise<LoginResponse> {
  const client = getClientApiClient()
  const response = await client.post<any>('/auth/login', {
    ...credentials,
    role: 'supplier',
  })

  // Backend returns access_token (snake_case), transform to accessToken (camelCase)
  const accessToken = response.data.access_token || response.data.accessToken
  const refreshToken = response.data.refresh_token || response.data.refreshToken
  const user = response.data.user

  if (typeof window !== 'undefined' && accessToken) {
    localStorage.setItem('auth_token', accessToken)
  }

  return {
    accessToken,
    refreshToken,
    user,
  }
}

export async function logout(): Promise<void> {
  const client = getClientApiClient()
  try {
    await client.post('/auth/logout')
  } catch (error) {
    console.error('Logout error:', error)
  } finally {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth_token')
    }
  }
}

export async function getCurrentUser(token?: string): Promise<User | null> {
  try {
    const client = getClientApiClient(token)
    const response = await client.get<{ user: User }>('/auth/me')
    return response.data.user
  } catch (error) {
    return null
  }
}

