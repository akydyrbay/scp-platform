import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { getDashboardStats } from '../../lib/api/dashboard'

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      get: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    })),
  },
}))

const mockedAxios = axios as any

describe('Dashboard API', () => {
  let mockClient: any

  beforeEach(() => {
    vi.clearAllMocks()
    mockClient = {
      get: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    }
    mockedAxios.create.mockReturnValue(mockClient)
  })

  describe('getDashboardStats', () => {
    it('should fetch and transform dashboard stats', async () => {
      const mockResponse = {
        data: {
          success: true,
          data: {
            total_orders: 100,
            pending_orders: 10,
            pending_link_requests: 5,
            low_stock_items: 3,
            recent_orders: [
              {
                id: 'order1',
                status: 'pending',
                total: 1000,
                items: [],
              },
            ],
            low_stock_products: [
              {
                id: 'product1',
                name: 'Product 1',
                stockLevel: 5,
              },
            ],
          },
        },
      }

      mockClient.get.mockResolvedValue(mockResponse)

      const result = await getDashboardStats('token')

      expect(result.total_orders).toBe(100)
      expect(result.totalOrders).toBe(100)
      expect(result.pending_orders).toBe(10)
      expect(result.pendingOrders).toBe(10)
      expect(result.pending_link_requests).toBe(5)
      expect(result.pendingLinkRequests).toBe(5)
      expect(result.low_stock_items).toBe(3)
      expect(result.lowStockItems).toBe(3)
      expect(result.recent_orders).toHaveLength(1)
      expect(result.recentOrders).toHaveLength(1)
      expect(result.low_stock_products).toHaveLength(1)
      expect(result.lowStockProducts).toHaveLength(1)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/dashboard/stats')
    })

    it('should throw error if API response is not successful', async () => {
      const mockResponse = {
        data: {
          success: false,
          error: {
            code: 'ERROR_CODE',
            message: 'Failed to fetch stats',
          },
        },
      }

      mockClient.get.mockResolvedValue(mockResponse)

      await expect(getDashboardStats('token')).rejects.toThrow('Failed to fetch stats')
    })

    it('should handle network errors', async () => {
      mockClient.get.mockRejectedValue(new Error('Network error'))

      await expect(getDashboardStats('token')).rejects.toThrow()
    })
  })
})

