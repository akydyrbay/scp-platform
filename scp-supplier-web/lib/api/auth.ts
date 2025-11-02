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
  const response = await client.post<LoginResponse>('/auth/login', {
    ...credentials,
    role: 'supplier',
  })

  if (typeof window !== 'undefined' && response.data.accessToken) {
    localStorage.setItem('auth_token', response.data.accessToken)
  }

  return response.data
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

