import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { getOrders, getOrder, acceptOrder, rejectOrder } from '../../lib/api/orders'

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      get: vi.fn(),
      post: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    })),
  },
}))

const mockedAxios = axios as any

describe('Orders API', () => {
  let mockClient: any

  beforeEach(() => {
    vi.clearAllMocks()
    mockClient = {
      get: vi.fn(),
      post: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    }
    mockedAxios.create.mockReturnValue(mockClient)
  })

  describe('getOrders', () => {
    it('should fetch all orders', async () => {
      const mockOrders = [
        {
          id: 'order1',
          status: 'pending',
          total: 1000,
          items: [],
        },
      ]

      mockClient.get.mockResolvedValue({ data: mockOrders })

      const result = await getOrders('token')

      expect(result).toEqual(mockOrders)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/orders')
    })
  })

  describe('getOrder', () => {
    it('should fetch a single order', async () => {
      const mockOrder = {
        id: 'order1',
        status: 'pending',
        total: 1000,
        items: [
          {
            id: 'item1',
            productId: 'product1',
            quantity: 10,
            unitPrice: 100,
            subtotal: 1000,
          },
        ],
      }

      mockClient.get.mockResolvedValue({ data: mockOrder })

      const result = await getOrder('order1', 'token')

      expect(result).toEqual(mockOrder)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/orders/order1')
    })
  })

  describe('acceptOrder', () => {
    it('should accept an order', async () => {
      const mockOrder = {
        id: 'order1',
        status: 'accepted',
        total: 1000,
      }

      mockClient.post.mockResolvedValue({ data: mockOrder })

      const result = await acceptOrder('order1', 'token')

      expect(result).toEqual(mockOrder)
      expect(result.status).toBe('accepted')
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/orders/order1/accept')
    })
  })

  describe('rejectOrder', () => {
    it('should reject an order', async () => {
      const mockOrder = {
        id: 'order1',
        status: 'rejected',
        total: 1000,
      }

      mockClient.post.mockResolvedValue({ data: mockOrder })

      const result = await rejectOrder('order1', 'token')

      expect(result).toEqual(mockOrder)
      expect(result.status).toBe('rejected')
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/orders/order1/reject')
    })
  })
})

