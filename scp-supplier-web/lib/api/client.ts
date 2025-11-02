import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://api.scp-platform.com/api/v1'

// Server-side client (takes token as parameter to avoid async issues)
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

// Client-side client
export function getClientApiClient(token?: string): AxiosInstance {
  const client = axios.create({
    baseURL: API_BASE_URL,
    timeout: 30000,
    headers: {
      'Content-Type': 'application/json',
    },
  })

  client.interceptors.request.use((config: InternalAxiosRequestConfig) => {
    const authToken = token || (typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null)
    
    if (authToken && config.headers) {
      config.headers.Authorization = `Bearer ${authToken}`
    }
    
    return config
  })

  client.interceptors.response.use(
    (response) => response,
    (error) => {
      if (error.response?.status === 401) {
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token')
          window.location.href = '/login'
        }
      }
      return Promise.reject(error)
    }
  )

  return client
}

