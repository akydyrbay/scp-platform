import { getClientApiClient } from './client'
import type { DashboardStats } from '../types'

interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: {
    code: string
    message: string
  }
}

export async function getDashboardStats(token?: string): Promise<DashboardStats> {
  const client = getClientApiClient(token)
  const response = await client.get<ApiResponse<DashboardStats>>('/supplier/dashboard/stats')
  
  if (!response.data.success || !response.data.data) {
    throw new Error(response.data.error?.message || 'Failed to fetch dashboard stats')
  }

  const stats = response.data.data

  // Transform snake_case to camelCase for frontend convenience
  return {
    ...stats,
    totalOrders: stats.total_orders,
    pendingOrders: stats.pending_orders,
    pendingLinkRequests: stats.pending_link_requests,
    lowStockItems: stats.low_stock_items,
    recentOrders: stats.recent_orders,
    lowStockProducts: stats.low_stock_products,
  }
}

