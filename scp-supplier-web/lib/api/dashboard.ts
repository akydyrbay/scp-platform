import { getClientApiClient } from './client'

export interface DashboardStats {
  total_orders: number
  pending_orders: number
  pending_link_requests: number
  low_stock_items: number
  recent_orders: any[]
  low_stock_products: any[]
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const client = getClientApiClient()
  
  try {
    console.log('Fetching dashboard stats from API...')
    const response = await client.get<DashboardStats | { success: boolean; data: DashboardStats }>('/supplier/dashboard/stats')
    
    console.log('Dashboard API response:', {
      status: response.status,
      hasData: !!response.data,
      dataType: typeof response.data,
      dataKeys: response.data ? Object.keys(response.data) : []
    })
    
    // Handle wrapped response format (success/data)
    if (response.data && typeof response.data === 'object' && 'success' in response.data && 'data' in response.data) {
      const wrappedData = (response.data as any).data
      if (wrappedData && 'total_orders' in wrappedData) {
        console.log('Dashboard stats loaded (wrapped format):', wrappedData)
        return {
          total_orders: wrappedData.total_orders || 0,
          pending_orders: wrappedData.pending_orders || 0,
          pending_link_requests: wrappedData.pending_link_requests || 0,
          low_stock_items: wrappedData.low_stock_items || 0,
          recent_orders: Array.isArray(wrappedData.recent_orders) ? wrappedData.recent_orders : [],
          low_stock_products: Array.isArray(wrappedData.low_stock_products) ? wrappedData.low_stock_products : [],
        }
      }
    }
    
    // If response format is direct (no wrapping)
    if (response.data && 'total_orders' in response.data) {
      const data = response.data as DashboardStats
      console.log('Dashboard stats loaded (direct format):', data)
      return {
        total_orders: data.total_orders || 0,
        pending_orders: data.pending_orders || 0,
        pending_link_requests: data.pending_link_requests || 0,
        low_stock_items: data.low_stock_items || 0,
        recent_orders: Array.isArray(data.recent_orders) ? data.recent_orders : [],
        low_stock_products: Array.isArray(data.low_stock_products) ? data.low_stock_products : [],
      }
    }
    
    console.warn('Unexpected dashboard response format:', response.data)
    throw new Error('Invalid response format from dashboard API')
  } catch (error: any) {
    const status = error?.response?.status

    // If the endpoint doesn't exist yet, quietly fall back to default stats
    if (status === 404) {
      console.warn('Dashboard stats endpoint not found (404). Returning default stats.')
      return {
        total_orders: 0,
        pending_orders: 0,
        pending_link_requests: 0,
        low_stock_items: 0,
        recent_orders: [],
        low_stock_products: []
      }
    }

    // Handle network errors
    if (error?.code === 'ECONNREFUSED' || error?.code === 'ERR_NETWORK') {
      console.error('Network error: Cannot connect to server')
      // Return default stats instead of throwing
      return {
        total_orders: 0,
        pending_orders: 0,
        pending_link_requests: 0,
        low_stock_items: 0,
        recent_orders: [],
        low_stock_products: []
      }
    }
    
    // Handle 500 errors gracefully
    if (status === 500) {
      const errorMessage = error.response?.data?.error?.message || 'Server error occurred'
      console.error('Dashboard API error:', errorMessage)
      // Return default stats instead of throwing
      return {
        total_orders: 0,
        pending_orders: 0,
        pending_link_requests: 0,
        low_stock_items: 0,
        recent_orders: [],
        low_stock_products: []
      }
    }
    
    // Return default stats if API fails
    return {
      total_orders: 0,
      pending_orders: 0,
      pending_link_requests: 0,
      low_stock_items: 0,
      recent_orders: [],
      low_stock_products: []
    }
  }
}

