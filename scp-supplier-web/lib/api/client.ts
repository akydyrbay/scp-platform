import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosError } from 'axios'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000/api/v1'

// Token storage keys
const ACCESS_TOKEN_KEY = 'auth_token'
const REFRESH_TOKEN_KEY = 'refresh_token'

// Helper functions for token storage
export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem(ACCESS_TOKEN_KEY)
}

export function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem(REFRESH_TOKEN_KEY)
}

export function setTokens(accessToken: string, refreshToken?: string): void {
  if (typeof window === 'undefined') return
  localStorage.setItem(ACCESS_TOKEN_KEY, accessToken)
  if (refreshToken) {
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken)
  }
}

export function clearTokens(): void {
  if (typeof window === 'undefined') return
  localStorage.removeItem(ACCESS_TOKEN_KEY)
  localStorage.removeItem(REFRESH_TOKEN_KEY)
}

// Refresh token function
async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = getRefreshToken()
  if (!refreshToken) return null

  // Check if already on login page to avoid redirect loops
  if (typeof window !== 'undefined' && window.location.pathname === '/login') {
    return null
  }

  try {
    const response = await axios.post<{ access_token: string }>(
      `${API_BASE_URL}/auth/refresh`,
      { refresh_token: refreshToken },
      { headers: { 'Content-Type': 'application/json' } }
    )

    const newAccessToken = response.data.access_token
    if (newAccessToken) {
      setTokens(newAccessToken)
      return newAccessToken
    }
    return null
  } catch (error) {
    clearTokens()
    // Don't redirect if already on login page or during logout
    if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
      // Use replace to avoid adding to history and causing loops
      window.location.replace('/login')
    }
    return null
  }
}

// Server-side client (takes token as parameter)
export function getServerApiClient(token?: string): AxiosInstance {
  const client = axios.create({
    baseURL: API_BASE_URL,
    timeout: 30000,
    headers: {
      'Content-Type': 'application/json',
    },
  })

  client.interceptors.request.use((config: InternalAxiosRequestConfig) => {
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  })

  return client
}

// Client-side client with automatic token refresh
export function getClientApiClient(token?: string): AxiosInstance {
  const client = axios.create({
    baseURL: API_BASE_URL,
    timeout: 30000,
    headers: {
      'Content-Type': 'application/json',
    },
    // Custom response transformer to handle JSON parsing errors
    transformResponse: [
      function (data, headers) {
        // If data is already parsed (object), return as is
        if (typeof data === 'object' && data !== null) {
          return data
        }
        
        // If data is a string, try to parse it
        if (typeof data === 'string') {
          // Remove any BOM or leading/trailing whitespace
          let cleaned = data.trim().replace(/^\uFEFF/, '')
          
          // If empty, return empty object
          if (!cleaned) {
            return {}
          }
          
          // Check content type
          const contentType = headers?.['content-type'] || headers?.['Content-Type'] || ''
          if (contentType && !contentType.includes('application/json')) {
            // If not JSON content type, check if it's HTML
            if (cleaned.includes('<!DOCTYPE') || cleaned.includes('<html')) {
              console.error('Received HTML instead of JSON:', {
                contentType,
                preview: cleaned.substring(0, 200)
              })
              throw new Error('Server returned HTML instead of JSON. Please check if the backend API is running correctly.')
            }
          }
          
          // Try to parse JSON
          try {
            // Remove any trailing characters that might cause issues
            // Find the last valid JSON character
            let jsonEnd = cleaned.length
            let braceCount = 0
            let bracketCount = 0
            let inString = false
            let escapeNext = false
            
            for (let i = 0; i < cleaned.length; i++) {
              const char = cleaned[i]
              
              if (escapeNext) {
                escapeNext = false
                continue
              }
              
              if (char === '\\') {
                escapeNext = true
                continue
              }
              
              if (char === '"') {
                inString = !inString
                continue
              }
              
              if (inString) continue
              
              if (char === '{') braceCount++
              if (char === '}') braceCount--
              if (char === '[') bracketCount++
              if (char === ']') bracketCount--
              
              // If we've closed all braces/brackets, this might be the end
              if (braceCount === 0 && bracketCount === 0 && (char === '}' || char === ']')) {
                jsonEnd = i + 1
                break
              }
            }
            
            // Try parsing the cleaned JSON
            const jsonString = cleaned.substring(0, jsonEnd)
            return JSON.parse(jsonString)
          } catch (e: any) {
            // Log the error with context
            const errorInfo: any = {
              error: e.message,
              errorPosition: e.message?.match(/position (\d+)/)?.[1],
              dataPreview: cleaned.substring(0, 500),
              dataLength: cleaned.length,
              contentType
            }
            
            // Try to find where the JSON ends
            const jsonStart = cleaned.indexOf('{')
            const jsonEnd = cleaned.lastIndexOf('}') + 1
            if (jsonStart !== -1 && jsonEnd > jsonStart) {
              errorInfo.jsonStart = jsonStart
              errorInfo.jsonEnd = jsonEnd
              errorInfo.afterJson = cleaned.substring(jsonEnd, Math.min(jsonEnd + 50, cleaned.length))
            }
            
            console.error('JSON parse error in transformResponse:', errorInfo)
            
            // Try to extract valid JSON if possible
            if (jsonStart !== -1 && jsonEnd > jsonStart) {
              try {
                const jsonString = cleaned.substring(jsonStart, jsonEnd)
                const parsed = JSON.parse(jsonString)
                console.log('Successfully extracted JSON from response')
                return parsed
              } catch (parseError) {
                // If extraction fails, continue with original error
              }
            }
            
            // If it's a specific JSON parse error, provide better message
            if (e.message?.includes('Unexpected') || e.message?.includes('JSON')) {
              throw new Error(`Invalid JSON response from server: ${e.message}. Please check if the backend API is running correctly.`)
            }
            
            throw e
          }
        }
        
        return data
      }
    ],
  })

  // Request interceptor: Add token to requests
  client.interceptors.request.use((config: InternalAxiosRequestConfig) => {
    const authToken = token || getAccessToken()
    if (authToken && config.headers) {
      config.headers.Authorization = `Bearer ${authToken}`
    }
    return config
  })

  // Response interceptor: Handle 401 and refresh token
  let isRefreshing = false
  let failedQueue: Array<{
    resolve: (value: string) => void
    reject: (error: AxiosError) => void
  }> = []

  const processQueue = (error: AxiosError | null, token: string | null = null) => {
    failedQueue.forEach((prom) => {
      if (error) {
        prom.reject(error)
      } else {
        prom.resolve(token || '')
      }
    })
    failedQueue = []
  }

  client.interceptors.response.use(
    (response) => {
      // Validate response is JSON
      const contentType = response.headers['content-type'] || response.headers['Content-Type']
      if (contentType && !contentType.includes('application/json')) {
        console.warn('Non-JSON response received:', {
          contentType,
          status: response.status,
          url: response.config?.url,
          dataPreview: typeof response.data === 'string' 
            ? response.data.substring(0, 200) 
            : response.data
        })
      }
      
      // Ensure response.data is an object (not a string that failed to parse)
      if (typeof response.data === 'string' && response.data.trim()) {
        try {
          const cleaned = response.data.trim().replace(/^\uFEFF/, '')
          if (cleaned && (cleaned.startsWith('{') || cleaned.startsWith('['))) {
            response.data = JSON.parse(cleaned)
          }
        } catch (e) {
          console.error('Failed to parse response data in interceptor:', {
            error: e,
            dataPreview: typeof response.data === 'string' ? response.data.substring(0, 200) : 'non-string',
            url: response.config?.url || response.request?.url || 'unknown'
          })
        }
      }
      
      return response
    },
    async (error: AxiosError) => {
      const originalRequest = (error.config || error.request) as InternalAxiosRequestConfig & { _retry?: boolean } | undefined

      // Handle HTTP errors first (before JSON parse errors)
      // This ensures 404, 403, 500 etc. are handled correctly even if there's a JSON parse issue
      if (error.response) {
        const status = error.response.status
        const errorData = error.response.data
        
        // For HTTP errors, try to parse the response data if it's a string
        if (typeof errorData === 'string' && errorData.trim()) {
          try {
            const cleaned = errorData.trim().replace(/^\uFEFF/, '')
            if (cleaned.startsWith('{') || cleaned.startsWith('[')) {
              const jsonStart = cleaned.indexOf('{')
              const jsonEnd = cleaned.lastIndexOf('}') + 1
              if (jsonStart !== -1 && jsonEnd > jsonStart) {
                const parsed = JSON.parse(cleaned.substring(jsonStart, jsonEnd))
                error.response.data = parsed
              }
            }
          } catch (parseError) {
            // If parsing fails, keep original error data
            console.warn('Failed to parse error response data:', parseError)
          }
        }
        
        // For 401, handle token refresh (don't return early)
        if (status === 401 && originalRequest && !originalRequest._retry) {
          // Will be handled below in the 401 section
        } else if (status !== 401) {
          // For non-401 errors, let them propagate normally
          // The error handler in the API function will handle them
          return Promise.reject(error)
        }
      }

      // Handle JSON parse errors (only if not already handled above)
      if (error.message?.includes('JSON') || error.message?.includes('Unexpected') || error.message?.includes('Invalid JSON')) {
        console.error('JSON parse error in response interceptor:', {
          message: error.message,
          response: error.response?.data,
          status: error.response?.status,
          headers: error.response?.headers,
          url: originalRequest?.url || error.config?.url || 'unknown'
        })
        
        // If response is HTML, it's likely an error page
        if (error.response?.data && typeof error.response.data === 'string') {
          if (error.response.data.includes('<!DOCTYPE') || error.response.data.includes('<html')) {
            const htmlError = new Error('Server returned an error page. Please check if the backend API is running correctly.')
            ;(htmlError as any).response = error.response
            ;(htmlError as any).code = 'ERR_BAD_RESPONSE'
            return Promise.reject(htmlError)
          }
          
          // Try to extract JSON from the string if it contains JSON
          try {
            const cleaned = error.response.data.trim().replace(/^\uFEFF/, '')
            const jsonStart = cleaned.indexOf('{')
            const jsonEnd = cleaned.lastIndexOf('}') + 1
            
            if (jsonStart !== -1 && jsonEnd > jsonStart) {
              const jsonString = cleaned.substring(jsonStart, jsonEnd)
              console.log('Extracting JSON from error response:', {
                jsonStart,
                jsonEnd,
                jsonLength: jsonString.length,
                afterJson: cleaned.substring(jsonEnd, Math.min(jsonEnd + 50, cleaned.length)),
                jsonPreview: jsonString.substring(0, 200)
              })
              
              const parsed = JSON.parse(jsonString)
              // If we successfully parsed JSON, create a successful response
              console.log('Successfully extracted JSON from error response')
              // Return a resolved promise with the parsed data
              return Promise.resolve({
                ...error.response,
                data: parsed,
                status: error.response.status,
                statusText: error.response.statusText,
                headers: error.response.headers,
                config: originalRequest
              } as any)
            } else {
              console.error('No valid JSON found in error response:', {
                dataPreview: cleaned.substring(0, 500),
                dataLength: cleaned.length
              })
              return Promise.reject(new Error(`Invalid JSON response from server: ${error.message}. Please check if the backend API is running correctly.`))
            }
          } catch (parseError: any) {
            console.error('Failed to extract JSON from error response:', {
              parseError: parseError.message,
              responsePreview: error.response.data.substring(0, 500)
            })
            // If parsing still fails, return a more helpful error
            return Promise.reject(new Error(`Invalid JSON response from server: ${error.message}. Please check if the backend API is running correctly.`))
          }
        } else {
          // For other JSON parsing issues, re-throw with a more generic message
          return Promise.reject(new Error(`Invalid JSON response from server: ${error.message}. Please check if the backend API is running correctly.`))
        }
      }

      // Handle 401 Unauthorized
      if (error.response?.status === 401 && originalRequest && !originalRequest._retry) {
        if (isRefreshing) {
          // If already refreshing, queue this request
          return new Promise((resolve, reject) => {
            failedQueue.push({ resolve, reject })
          })
            .then((token) => {
              if (originalRequest?.headers) {
                originalRequest.headers.Authorization = `Bearer ${token}`
              }
              return client(originalRequest!)
            })
            .catch((err) => {
              return Promise.reject(err)
            })
        }

        if (originalRequest) {
          originalRequest._retry = true
        }
        isRefreshing = true

        const newToken = await refreshAccessToken()

        if (newToken && originalRequest) {
          processQueue(null, newToken)
          if (originalRequest.headers) {
            originalRequest.headers.Authorization = `Bearer ${newToken}`
          }
          return client(originalRequest)
        } else {
          processQueue(error as AxiosError)
          clearTokens()
          // Only redirect if not already on login page and not during logout
          if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
            // Check if this is a logout request - don't redirect during logout
            if (!originalRequest?.url?.includes('/auth/logout')) {
              window.location.replace('/login')
            }
          }
          return Promise.reject(error)
        }
      }

      return Promise.reject(error)
    }
  )

  return client
}

