import { getClientApiClient } from './client'

export interface OrderItem {
  id: string
  order_id: string
  product_id: string
  quantity: number
  unit_price: number
  subtotal: number
  product?: {
    id: string
    name: string
    unit: string
  }
  created_at: string
}

export interface Order {
  id: string
  consumer_id: string
  supplier_id: string
  supplier_name?: string
  consumer_name?: string | null
  status: string
  subtotal: number
  tax: number
  shipping_fee: number
  total: number
  delivery_date?: string | null
  delivery_start_time?: string | null
  delivery_end_time?: string | null
  notes?: string | null
  preferred_settlement?: string | null
  created_at: string
  updated_at?: string | null
  items?: OrderItem[]
}

export interface PaginatedOrders {
  results: Order[]
  pagination: {
    page: number
    page_size: number
    total: number
    total_pages: number
  }
}

export async function getOrders(page = 1, pageSize = 20): Promise<PaginatedOrders> {
  const client = getClientApiClient()
  
  try {
    const response = await client.get<PaginatedOrders>('/supplier/orders', {
      params: { page, page_size: pageSize },
    })
    
    // Handle different response formats
    if (response.data && 'results' in response.data) {
      return response.data
    }
    
    // If response format is different (wrapped in success/data)
    if (response.data && 'success' in response.data && (response.data as any).success) {
      const data = (response.data as any).data
      if (data && 'results' in data) {
        return data
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
    // Handle 500 errors gracefully
    if (error.response?.status === 500) {
      const errorMessage = error.response?.data?.error?.message || 'Server error occurred'
      console.error('Orders API error:', errorMessage)
    } else {
      console.error('Failed to fetch orders:', error)
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

export async function getOrder(id: string): Promise<Order> {
  const client = getClientApiClient()
  const response = await client.get<Order>(`/supplier/orders/${id}`)
  return response.data
}

export async function acceptOrder(id: string): Promise<void> {
  const client = getClientApiClient()
  await client.post(`/supplier/orders/${id}/accept`)
}

export async function rejectOrder(id: string): Promise<void> {
  const client = getClientApiClient()
  await client.post(`/supplier/orders/${id}/reject`)
}

