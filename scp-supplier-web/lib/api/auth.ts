import { getClientApiClient, getServerApiClient, setTokens, clearTokens } from './client'

// Backend user type
export interface BackendUser {
  id: string
  email: string
  first_name?: string | null
  last_name?: string | null
  company_name?: string | null
  phone_number?: string | null
  role: string
  profile_image_url?: string | null
  supplier_id?: string | null
  created_at: string
  updated_at?: string | null
}

// Frontend user type (compatible with existing UI)
export interface User {
  id: string
  name: string
  email: string
  role: 'owner' | 'manager' | 'sales'
  company_name?: string | null
  supplier_id?: string | null
}

// Login request
export interface LoginCredentials {
  email: string
  password: string
  role?: 'owner' | 'manager' | 'sales_rep'
}

// Login response from backend
interface LoginResponse {
  access_token: string
  refresh_token: string
  user: BackendUser
}

// Map backend role to frontend role
function mapRole(backendRole: string): 'owner' | 'manager' | 'sales' {
  switch (backendRole) {
    case 'owner':
      return 'owner'
    case 'manager':
      return 'manager'
    case 'sales_rep':
      return 'sales'
    default:
      return 'manager'
  }
}

// Convert backend user to frontend user
function mapUser(backendUser: BackendUser): User {
  const firstName = backendUser.first_name || ''
  const lastName = backendUser.last_name || ''
  const name = `${firstName} ${lastName}`.trim() || backendUser.email.split('@')[0]

  return {
    id: backendUser.id,
    name,
    email: backendUser.email,
    role: mapRole(backendUser.role),
    company_name: backendUser.company_name ?? null,
    supplier_id: backendUser.supplier_id ?? null,
  }
}

// Login function
export async function login(credentials: LoginCredentials): Promise<{ user: User; redirect: string }> {
  const client = getClientApiClient()

  // Try to login with provided role, or try common roles for supplier portal
  const rolesToTry = credentials.role 
    ? [credentials.role]
    : ['owner', 'manager', 'sales_rep']

  let lastError: any = null

  for (const role of rolesToTry) {
    try {
      const response = await client.post<LoginResponse>('/auth/login', {
        email: credentials.email,
        password: credentials.password,
        role,
      }, {
        // Ensure we get JSON response
        responseType: 'json',
        // Validate status
        validateStatus: (status) => status >= 200 && status < 300,
      })

      // Log response for debugging
      console.log('Login response received:', {
        status: response.status,
        hasData: !!response.data,
        dataKeys: response.data ? Object.keys(response.data) : [],
        contentType: response.headers['content-type']
      })

      // Validate response structure
      if (!response.data) {
        console.error('Empty login response:', response)
        throw new Error('Empty response from server. Please try again.')
      }

      // Handle wrapped response format (success/data)
      let loginData = response.data
      if (loginData && typeof loginData === 'object' && 'success' in loginData && 'data' in loginData) {
        loginData = (loginData as any).data
      }

      if (!loginData || !loginData.access_token || !loginData.user) {
        console.error('Invalid login response structure:', {
          responseData: response.data,
          loginData,
          hasAccessToken: !!loginData?.access_token,
          hasUser: !!loginData?.user
        })
        throw new Error('Invalid response format from server. Please try again.')
      }

      // Store tokens
      setTokens(loginData.access_token, loginData.refresh_token)

      // Map user
      const user = mapUser(loginData.user)

      // Determine redirect based on role
      const redirectMap: Record<string, string> = {
        owner: '/owner/dashboard',
        manager: '/manager/dashboard',
        sales: '/sales/dashboard',
      }
      const redirect = redirectMap[user.role] || '/manager/dashboard'

      return { user, redirect }
    } catch (error: any) {
      lastError = error
      
      // Handle JSON parse errors
      if (error.message?.includes('JSON') || error.message?.includes('Unexpected')) {
        console.error('JSON parse error:', error)
        // Check if response is HTML (error page)
        if (error.response?.data && typeof error.response.data === 'string') {
          if (error.response.data.includes('<!DOCTYPE') || error.response.data.includes('<html')) {
            throw new Error('Server returned an error page. Please check if the backend API is running correctly.')
          }
        }
        throw new Error('Invalid response format from server. Please check if the backend API is running and configured correctly.')
      }
      
      // If it's a role mismatch error, try next role
      if (error.response?.status === 401) {
        const errorMessage = error.response?.data?.error?.message || 
                            error.response?.data?.message || 
                            ''
        if (errorMessage.includes('role') || errorMessage.includes('Role') || errorMessage.includes('Invalid role')) {
          // Continue to next role
          continue
        }
      }
      
      // If it's a network error or other non-auth error, break immediately
      if (error.code === 'ECONNREFUSED' || error.code === 'ERR_NETWORK' || error.message?.includes('Network Error')) {
        throw new Error('Cannot connect to server. Please check if the backend API is running and ensure NEXT_PUBLIC_API_BASE_URL is configured correctly.')
      }
      
      if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
        throw new Error('Request timeout. Please check your network connection or try again later.')
      }
      
      // If we've tried all roles or it's not a role error, break
      if (rolesToTry.indexOf(role) === rolesToTry.length - 1) {
        break
      }
    }
  }

  // If we get here, all login attempts failed
  if (lastError) {
    // Handle JSON parse errors
    if (lastError.message?.includes('JSON') || lastError.message?.includes('Unexpected')) {
      console.error('JSON parse error in login:', lastError)
      // Check if response is HTML (error page)
      if (lastError.response?.data && typeof lastError.response.data === 'string') {
        if (lastError.response.data.includes('<!DOCTYPE') || lastError.response.data.includes('<html')) {
          throw new Error('Server returned an error page. Please check if the backend API is running correctly.')
        }
      }
      throw new Error('Invalid response format from server. Please check if the backend API is running and configured correctly.')
    }
    
    // Handle network errors
    if (lastError.code === 'ECONNREFUSED' || lastError.code === 'ERR_NETWORK' || lastError.message?.includes('Network Error')) {
      throw new Error('Cannot connect to server. Please check if the backend API is running and ensure NEXT_PUBLIC_API_BASE_URL is configured correctly.')
    }
    
    // Handle timeout errors
    if (lastError.code === 'ECONNABORTED' || lastError.message?.includes('timeout')) {
      throw new Error('Request timeout. Please check your network connection or try again later.')
    }
    
    // Handle API errors
    if (lastError.response) {
      // Try to extract error message from different response formats
      let message = ''
      
      if (lastError.response.data) {
        if (typeof lastError.response.data === 'string') {
          // Response is a string, might be HTML or plain text
          if (lastError.response.data.includes('<!DOCTYPE') || lastError.response.data.includes('<html')) {
            message = 'Server returned an error page. Please check if the backend API is running correctly.'
          } else {
            message = lastError.response.data
          }
        } else if (typeof lastError.response.data === 'object') {
          message = lastError.response.data?.error?.message || 
                   lastError.response.data?.message ||
                   `Login failed: ${lastError.response.status} ${lastError.response.statusText}`
        }
      }
      
      if (!message) {
        message = `Login failed: ${lastError.response.status} ${lastError.response.statusText}`
      }
      
      throw new Error(message)
    }
    
    // Handle other errors
    const message = lastError.message || 'Login failed. Please check your credentials or network connection.'
    throw new Error(message)
  }

  throw new Error('Login failed. Please check your credentials.')
}

// Logout function
export async function logout(): Promise<void> {
  // Clear tokens first to prevent token refresh during logout
  clearTokens()
  
  try {
    const client = getClientApiClient()
    // Try to call logout endpoint, but don't wait or fail if it errors
    // This is best effort - tokens are already cleared
    await client.post('/auth/logout').catch(() => {
      // Ignore errors during logout - tokens are already cleared
    })
  } catch (error) {
    // Ignore errors - tokens are already cleared
    console.log('Logout endpoint call failed (tokens already cleared)')
  }
}

// Get current user's full backend data (client-side)
export async function getCurrentUserBackend(token?: string): Promise<BackendUser | null> {
  try {
    const client = token ? getClientApiClient(token) : getClientApiClient()
    const response = await client.get<BackendUser>('/auth/me')
    return response.data
  } catch (error: any) {
    // If 401, token is invalid - return null without redirecting
    if (error.response?.status === 401) {
      return null
    }
    // For other errors, also return null
    return null
  }
}

// Get current user (client-side)
export async function getCurrentUser(token?: string): Promise<User | null> {
  try {
    const backendUser = await getCurrentUserBackend(token)
    if (!backendUser) return null
    return mapUser(backendUser)
  } catch (error: any) {
    return null
  }
}

// Get current user (server-side)
export async function getCurrentUserServer(token: string): Promise<User | null> {
  try {
    const client = getServerApiClient(token)
    const response = await client.get<BackendUser>('/auth/me')
    return mapUser(response.data)
  } catch (error) {
    return null
  }
}

// Refresh token function
export async function refreshToken(): Promise<string | null> {
  const client = getClientApiClient()

  try {
    const refreshToken = typeof window !== 'undefined' ? localStorage.getItem('refresh_token') : null
    if (!refreshToken) {
      throw new Error('No refresh token available')
    }

    const response = await client.post<{ access_token: string }>('/auth/refresh', {
      refresh_token: refreshToken,
    })

    if (response.data.access_token) {
      setTokens(response.data.access_token)
      return response.data.access_token
    }

    return null
  } catch (error) {
    clearTokens()
    throw error
  }
}
