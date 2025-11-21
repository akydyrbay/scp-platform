// Cookie names
const ACCESS_TOKEN_KEY = 'auth_token'
const REFRESH_TOKEN_KEY = 'refresh_token'
const USER_DATA_KEY = 'user_data'

// Helper to get cookie value by name
function getCookie(name: string): string | null {
  if (typeof document === 'undefined') return null
  
  const nameEQ = name + '='
  const ca = document.cookie.split(';')
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i]
    while (c.charAt(0) === ' ') c = c.substring(1, c.length)
    if (c.indexOf(nameEQ) === 0) return decodeURIComponent(c.substring(nameEQ.length, c.length))
  }
  return null
}

// Helper to set cookie
function setCookie(name: string, value: string, days: number = 7): void {
  if (typeof document === 'undefined') return
  
  const expires = new Date()
  expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
  
  const secure = process.env.NODE_ENV === 'production' ? '; Secure' : ''
  const sameSite = '; SameSite=Strict'
  document.cookie = `${name}=${encodeURIComponent(value)}; expires=${expires.toUTCString()}; path=/${secure}${sameSite}`
}

// Helper to delete cookie
function deleteCookie(name: string): void {
  if (typeof document === 'undefined') return
  document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`
}

// Helper functions for token storage using cookies
export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null
  return getCookie(ACCESS_TOKEN_KEY)
}

export function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null
  return getCookie(REFRESH_TOKEN_KEY)
}

export function setTokens(accessToken: string, refreshToken?: string): void {
  if (typeof window === 'undefined') return
  
  // Set access token (expires in 15 minutes to match JWT expiry, but we'll use 7 days for convenience)
  // In production, you might want to match JWT expiry exactly
  setCookie(ACCESS_TOKEN_KEY, accessToken, 7)
  
  // Set refresh token if provided (expires in 7 days)
  if (refreshToken) {
    setCookie(REFRESH_TOKEN_KEY, refreshToken, 7)
  }
}

export function clearTokens(): void {
  if (typeof window === 'undefined') return
  
  // Remove tokens
  deleteCookie(ACCESS_TOKEN_KEY)
  deleteCookie(REFRESH_TOKEN_KEY)
  deleteCookie(USER_DATA_KEY)
}

// Check if user is authenticated (has access token cookie)
export function isAuthenticated(): boolean {
  if (typeof window === 'undefined') return false
  return !!getCookie(ACCESS_TOKEN_KEY)
}

// Store user data in cookie (optional, for quick access)
export function setUserData(userData: string): void {
  if (typeof window === 'undefined') return
  setCookie(USER_DATA_KEY, userData, 7)
}

export function getUserData(): string | null {
  if (typeof window === 'undefined') return null
  return getCookie(USER_DATA_KEY)
}

