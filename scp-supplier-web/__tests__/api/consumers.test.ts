import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import {
  getConsumerLinks,
  approveConsumerLink,
  rejectConsumerLink,
  blockConsumer,
  unlinkConsumer,
} from '../../lib/api/consumers'

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

describe('Consumers API', () => {
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

  describe('getConsumerLinks', () => {
    it('should fetch all consumer links', async () => {
      const mockLinks = [
        {
          id: 'link1',
          consumerId: 'consumer1',
          status: 'pending',
        },
      ]

      mockClient.get.mockResolvedValue({ data: mockLinks })

      const result = await getConsumerLinks('token')

      expect(result).toEqual(mockLinks)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/consumer-links')
    })
  })

  describe('approveConsumerLink', () => {
    it('should approve a consumer link', async () => {
      const mockLink = {
        id: 'link1',
        status: 'approved',
      }

      mockClient.post.mockResolvedValue({ data: mockLink })

      const result = await approveConsumerLink('link1', 'token')

      expect(result.status).toBe('approved')
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/consumer-links/link1/approve')
    })
  })

  describe('rejectConsumerLink', () => {
    it('should reject a consumer link', async () => {
      const mockLink = {
        id: 'link1',
        status: 'rejected',
      }

      mockClient.post.mockResolvedValue({ data: mockLink })

      const result = await rejectConsumerLink('link1', 'token')

      expect(result.status).toBe('rejected')
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/consumer-links/link1/reject')
    })
  })

  describe('blockConsumer', () => {
    it('should block a consumer', async () => {
      mockClient.post.mockResolvedValue({ data: {} })

      await blockConsumer('consumer1', 'token')

      expect(mockClient.post).toHaveBeenCalledWith('/supplier/consumers/consumer1/block')
    })
  })

  describe('unlinkConsumer', () => {
    it('should unlink a consumer', async () => {
      mockClient.post.mockResolvedValue({ data: {} })

      await unlinkConsumer('consumer1', 'token')

      expect(mockClient.post).toHaveBeenCalledWith('/supplier/consumers/consumer1/unlink')
    })
  })
})

