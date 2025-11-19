import { getClientApiClient } from './client'
import type { User } from '../types'
import { transformUser } from '../utils/transform'

export interface LoginCredentials {
  email: string
  password: string
  role?: 'supplier' | 'owner' | 'manager' | 'sales_rep'
}

export interface LoginResponse {
  accessToken: string
  refreshToken?: string
  user: User
}

export async function login(credentials: LoginCredentials): Promise<LoginResponse> {
  const client = getClientApiClient()
  
  // Determine which roles to try
  let rolesToTry: Array<'owner' | 'manager' | 'sales_rep'> = []
  
  if (credentials.role && (credentials.role === 'owner' || credentials.role === 'manager' || credentials.role === 'sales_rep')) {
    // If explicit supplier role provided, try it first, then others
    rolesToTry = [credentials.role, ...(['owner', 'manager', 'sales_rep'] as const).filter(r => r !== credentials.role)]
  } else {
    // If no role or non-supplier role, try all supplier roles
    rolesToTry = ['owner', 'manager', 'sales_rep']
  }

  let lastError: any = null

  for (const role of rolesToTry) {
    try {
  const response = await client.post<any>('/auth/login', {
        email: credentials.email,
        password: credentials.password,
        role,
  })

  const accessToken = response.data.access_token || response.data.accessToken
  const refreshToken = response.data.refresh_token || response.data.refreshToken
      const userData = response.data.user

  if (typeof window !== 'undefined' && accessToken) {
    localStorage.setItem('auth_token', accessToken)
  }

  return {
    accessToken,
    refreshToken,
        user: transformUser(userData),
  }
    } catch (error: any) {
      lastError = error
      
      // If it's a 400 error (bad request), throw immediately - don't try other roles
      if (error.response?.status === 400) {
        throw error
      }
      
      // If it's a 401 error (unauthorized), try the next role
      // This could be due to wrong role or wrong password
      // If it's wrong password, all roles will fail
      // If it's wrong role, we'll find the right one
      if (error.response?.status === 401) {
        continue
      }
      
      // For other errors, throw immediately
      throw error
    }
  }

  // If all roles failed, throw the last error
  throw lastError || new Error('Login failed. Please check your credentials.')
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
    // Backend returns user directly, not wrapped in { user: ... }
    const response = await client.get<any>('/auth/me')
    return transformUser(response.data)
  } catch (error) {
    return null
  }
}

