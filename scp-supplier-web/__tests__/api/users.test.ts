import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { getUsers, createUser, deleteUser } from '../../lib/api/users'

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      get: vi.fn(),
      post: vi.fn(),
      delete: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    })),
  },
}))

const mockedAxios = axios as any

describe('Users API', () => {
  let mockClient: any

  beforeEach(() => {
    vi.clearAllMocks()
    mockClient = {
      get: vi.fn(),
      post: vi.fn(),
      delete: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    }
    mockedAxios.create.mockReturnValue(mockClient)
  })

  describe('getUsers', () => {
    it('should fetch all users', async () => {
      const mockUsers = [
        {
          id: 'user1',
          email: 'manager@example.com',
          role: 'manager',
        },
        {
          id: 'user2',
          email: 'sales@example.com',
          role: 'sales_rep',
        },
      ]

      mockClient.get.mockResolvedValue({ data: mockUsers })

      const result = await getUsers('token')

      expect(result).toEqual(mockUsers)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/users')
    })
  })

  describe('createUser', () => {
    it('should create a new user', async () => {
      const userData = {
        email: 'newuser@example.com',
        password: 'password123',
        firstName: 'New',
        lastName: 'User',
        role: 'manager' as const,
      }

      const mockUser = {
        id: 'user3',
        ...userData,
      }

      mockClient.post.mockResolvedValue({ data: mockUser })

      const result = await createUser(userData, 'token')

      expect(result).toEqual(mockUser)
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/users', userData)
    })
  })

  describe('deleteUser', () => {
    it('should delete a user', async () => {
      mockClient.delete.mockResolvedValue({ data: {} })

      await deleteUser('user1', 'token')

      expect(mockClient.delete).toHaveBeenCalledWith('/supplier/users/user1')
    })
  })
})

