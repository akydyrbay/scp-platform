import { getClientApiClient } from './client'

export interface Consumer {
  id: string
  email: string
  first_name?: string | null
  last_name?: string | null
  company_name?: string | null
  phone_number?: string | null
}

export interface Complaint {
  id: string
  conversation_id: string
  consumer_id: string
  supplier_id: string
  order_id?: string | null
  title: string
  description: string
  priority: 'low' | 'medium' | 'high' | 'urgent'
  status: 'open' | 'escalated' | 'resolved' | 'closed'
  escalated_by?: string | null
  escalated_at?: string | null
  resolved_at?: string | null
  resolution?: string | null
  created_at: string
  updated_at?: string | null
  consumer?: Consumer | null
}

export interface PaginatedComplaints {
  results: Complaint[]
  page: number
  page_size: number
  total: number
}

// Backend response format with pagination object
interface BackendPaginatedResponse {
  results: Complaint[]
  pagination: {
    page: number
    page_size: number
    total: number
    total_pages: number
  }
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  sender_role: string
  content: string
  created_at: string
}

/**
 * Get complaints list with optional status filter
 */
export async function getComplaints(page = 1, pageSize = 20, status?: string): Promise<PaginatedComplaints> {
  const client = getClientApiClient()
  const params = new URLSearchParams({
    page: page.toString(),
    page_size: pageSize.toString()
  })
  if (status) {
    params.append('status', status)
  }
  
  try {
    const response = await client.get<PaginatedComplaints | BackendPaginatedResponse | { success: boolean; data: PaginatedComplaints }>(
      `/supplier/complaints?${params.toString()}`
    )
    
    // Handle wrapped response format (success/data)
    if (response.data && 'success' in response.data && response.data.success && response.data.data) {
      const data = response.data.data
      // Check if it has pagination object
      if ('pagination' in data) {
        const backendData = data as any
        return {
          results: backendData.results || [],
          page: backendData.pagination?.page || page,
          page_size: backendData.pagination?.page_size || pageSize,
          total: backendData.pagination?.total || 0
        }
      }
      return data
    }
    
    // Handle backend format with pagination object
    if (response.data && 'pagination' in response.data) {
      const backendData = response.data as BackendPaginatedResponse
      return {
        results: backendData.results || [],
        page: backendData.pagination.page,
        page_size: backendData.pagination.page_size,
        total: backendData.pagination.total
      }
    }
    
    // Handle direct response format (results at top level)
    if (response.data && 'results' in response.data) {
      return response.data as PaginatedComplaints
    }
    
    throw new Error('Invalid response format from complaints API')
  } catch (error: any) {
    console.error('Failed to fetch complaints:', error)
    if (error.response?.status === 500) {
      throw new Error('Server error occurred while fetching complaints')
    }
    throw new Error(error.message || 'Failed to fetch complaints')
  }
}

/**
 * Get a single complaint by ID
 */
export async function getComplaint(id: string): Promise<Complaint> {
  const client = getClientApiClient()
  
  try {
    console.log('Fetching complaint with ID:', id)
    const response = await client.get<Complaint | { success: boolean; data: Complaint }>(
      `/supplier/complaints/${id}`
    )
    
    console.log('Complaint API response:', {
      status: response.status,
      hasData: !!response.data,
      dataType: typeof response.data,
      dataKeys: response.data && typeof response.data === 'object' ? Object.keys(response.data) : 'N/A'
    })
    
    // Handle wrapped response format (success/data)
    if (response.data && typeof response.data === 'object' && 'success' in response.data) {
      const wrapped = response.data as { success: boolean; data: Complaint }
      if (wrapped.success && wrapped.data) {
        console.log('Complaint fetched successfully (wrapped format):', wrapped.data.id)
        return wrapped.data
      }
    }
    
    // Handle direct response format
    if (response.data && typeof response.data === 'object' && 'id' in response.data) {
      console.log('Complaint fetched successfully (direct format):', (response.data as Complaint).id)
      return response.data as Complaint
    }
    
    console.error('Unexpected response format:', response.data)
    throw new Error('Invalid complaint response format from server')
  } catch (error: any) {
    // Log detailed error information
    console.error('Failed to fetch complaint:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status,
      statusText: error.response?.statusText,
      url: error.config?.url || error.request?.url,
      code: error.code,
      isAxiosError: error.isAxiosError
    })
    
    // Handle HTTP errors first (before JSON parse errors)
    if (error.response) {
      const status = error.response.status
      const errorData = error.response.data
      
      if (status === 404) {
        const errorMessage = errorData?.error?.message || errorData?.message || 'Complaint not found'
        throw new Error(errorMessage)
      }
      
      if (status === 403) {
        const errorMessage = errorData?.error?.message || errorData?.message || 'You do not have permission to access this complaint'
        throw new Error(errorMessage)
      }
      
      if (status === 500) {
        const errorMessage = errorData?.error?.message || errorData?.message || 'Server error occurred. Please try again later.'
        throw new Error(errorMessage)
      }
      
      // For other HTTP errors, use the error message from response
      if (errorData?.error?.message || errorData?.message) {
        throw new Error(errorData.error?.message || errorData.message)
      }
    }
    
    // Handle JSON parse errors specifically (only if not already handled above)
    if (error.message?.includes('JSON') || error.message?.includes('Unexpected') || error.message?.includes('Invalid JSON')) {
      // Check if response is HTML
      if (error.response?.data && typeof error.response.data === 'string') {
        if (error.response.data.includes('<!DOCTYPE') || error.response.data.includes('<html')) {
          throw new Error('Server returned an error page. Please check if the backend API is running correctly.')
        }
      }
      // Only throw JSON error if we don't have a valid HTTP status
      if (!error.response?.status) {
        throw new Error(`Invalid JSON response from server: ${error.message}. Please check if the backend API is running correctly.`)
      }
    }
    
    // Handle network errors
    if (error.code === 'ECONNREFUSED' || error.code === 'ERR_NETWORK' || error.message?.includes('Network Error')) {
      throw new Error('Cannot connect to server. Please check if the backend API is running.')
    }
    
    // Handle timeout errors
    if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      throw new Error('Request timeout. Please try again later.')
    }
    
    // Default error message
    throw new Error(error.message || 'Failed to fetch complaint')
  }
}

/**
 * Get conversation messages for a complaint (used as history)
 */
export async function getConversationMessages(conversationId: string): Promise<Message[]> {
  const client = getClientApiClient()
  
  try {
    const response = await client.get<{ results: Message[] } | Message[]>(
      `/supplier/conversations/${conversationId}/messages?page=1&page_size=100`
    )
    
    if (Array.isArray(response.data)) {
      return response.data
    }
    
    if (response.data && 'results' in response.data) {
      return response.data.results
    }
    
    return []
  } catch (error: any) {
    console.error('Failed to fetch conversation messages:', error)
    return []
  }
}

/**
 * Resolve a complaint
 */
export async function resolveComplaint(id: string, resolution: string): Promise<Complaint> {
  const client = getClientApiClient()
  
  try {
    const response = await client.post<Complaint | { success: boolean; data: Complaint }>(
      `/supplier/complaints/${id}/resolve`,
      { resolution }
    )
    
    // Handle wrapped response format
    if (response.data && 'success' in response.data && response.data.success && response.data.data) {
      return response.data.data
    }
    
    // Handle direct response format
    return response.data as Complaint
  } catch (error: any) {
    console.error('Failed to resolve complaint:', error)
    if (error.response?.status === 400) {
      const message = error.response?.data?.error?.message || error.response?.data?.message || 'Invalid resolution'
      throw new Error(message)
    }
    throw new Error(error.message || 'Failed to resolve complaint')
  }
}

/**
 * Escalate a complaint
 */
export async function escalateComplaint(id: string): Promise<Complaint> {
  const client = getClientApiClient()
  
  try {
    const response = await client.post<Complaint | { success: boolean; data: Complaint }>(
      `/supplier/complaints/${id}/escalate`,
      {}
    )
    
    // Handle wrapped response format
    if (response.data && 'success' in response.data && response.data.success && response.data.data) {
      return response.data.data
    }
    
    // Handle direct response format
    return response.data as Complaint
  } catch (error: any) {
    console.error('Failed to escalate complaint:', error)
    throw new Error(error.message || 'Failed to escalate complaint')
  }
}

