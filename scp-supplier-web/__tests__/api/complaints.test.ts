import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { getComplaints, getComplaint, resolveComplaint } from '../../lib/api/complaints'

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

describe('Complaints API', () => {
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

  describe('getComplaints', () => {
    it('should fetch all complaints', async () => {
      const mockComplaints = [
        {
          id: 'complaint1',
          title: 'Test Complaint',
          status: 'open',
          priority: 'high',
        },
      ]

      mockClient.get.mockResolvedValue({ data: mockComplaints })

      const result = await getComplaints('token')

      expect(result).toEqual(mockComplaints)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/complaints')
    })
  })

  describe('getComplaint', () => {
    it('should fetch a single complaint', async () => {
      const mockComplaint = {
        id: 'complaint1',
        title: 'Test Complaint',
        description: 'Description',
        status: 'open',
        priority: 'high',
      }

      mockClient.get.mockResolvedValue({ data: mockComplaint })

      const result = await getComplaint('complaint1', 'token')

      expect(result).toEqual(mockComplaint)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/complaints/complaint1')
    })
  })

  describe('resolveComplaint', () => {
    it('should resolve a complaint with resolution notes', async () => {
      const resolveData = {
        resolution: 'Issue resolved by providing replacement',
      }

      const mockComplaint = {
        id: 'complaint1',
        status: 'resolved',
        resolvedAt: '2024-01-02T00:00:00Z',
      }

      mockClient.post.mockResolvedValue({ data: mockComplaint })

      const result = await resolveComplaint('complaint1', resolveData, 'token')

      expect(result.status).toBe('resolved')
      expect(mockClient.post).toHaveBeenCalledWith(
        '/supplier/complaints/complaint1/resolve',
        resolveData
      )
    })
  })
})

