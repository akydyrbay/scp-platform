import { getClientApiClient } from './client'

export interface ConsumerLink {
  id: string
  consumer_id: string
  supplier_id: string
  status: string
  requested_at: string
  approved_at?: string | null
  rejected_at?: string | null
}

export interface PaginatedConsumerLinks {
  results: ConsumerLink[]
  pagination: {
    page: number
    page_size: number
    total: number
    total_pages: number
  }
}

export async function getConsumerLinks(page = 1, pageSize = 20): Promise<PaginatedConsumerLinks> {
  const client = getClientApiClient()
  
  try {
    const response = await client.get<PaginatedConsumerLinks>('/supplier/consumer-links', {
      params: { page, page_size: pageSize },
    })
    
    // Handle different response formats
    if (response.data && 'results' in response.data) {
      return {
        results: Array.isArray(response.data.results) ? response.data.results : [],
        pagination: response.data.pagination || {
          page,
          page_size: pageSize,
          total: 0,
          total_pages: 0,
        },
      }
    }
    
    // If response format is different (wrapped in success/data)
    if (response.data && 'success' in response.data && (response.data as any).success) {
      const data = (response.data as any).data
      if (data && 'results' in data) {
        return {
          results: Array.isArray(data.results) ? data.results : [],
          pagination: data.pagination || {
            page,
            page_size: pageSize,
            total: 0,
            total_pages: 0,
          },
        }
      }
    }
    
    // Return empty paginated response if format is unexpected
    return {
      results: [],
      pagination: {
        page,
        page_size: pageSize,
        total: 0,
        total_pages: 0,
      },
    }
  } catch (error: any) {
    // Handle errors gracefully
    if (error.response?.status === 500) {
      const errorMessage = error.response?.data?.error?.message || 'Server error occurred'
      console.error('Consumer links API error:', errorMessage)
    } else {
      console.error('Failed to fetch consumer links:', error)
    }
    
    // Return empty paginated response instead of throwing
    return {
      results: [],
      pagination: {
        page,
        page_size: pageSize,
        total: 0,
        total_pages: 0,
      },
    }
  }
}

export async function approveLink(id: string): Promise<void> {
  const client = getClientApiClient()
  await client.post(`/supplier/consumer-links/${id}/approve`)
}

export async function rejectLink(id: string): Promise<void> {
  const client = getClientApiClient()
  await client.post(`/supplier/consumer-links/${id}/reject`)
}

export async function blockLink(id: string): Promise<void> {
  const client = getClientApiClient()
  await client.post(`/supplier/consumer-links/${id}/block`)
}

