import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import {
  getProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  bulkUpdateProducts,
} from '../../lib/api/products'

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => ({
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    })),
  },
}))

const mockedAxios = axios as any

describe('Products API', () => {
  let mockClient: any

  beforeEach(() => {
    vi.clearAllMocks()
    mockClient = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn() },
      },
    }
    mockedAxios.create.mockReturnValue(mockClient)
  })

  describe('getProducts', () => {
    it('should fetch all products', async () => {
      const mockProducts = [
        {
          id: 'product1',
          name: 'Test Product',
          price: 100,
          stockLevel: 50,
          unit: 'kg',
        },
      ]

      mockClient.get.mockResolvedValue({ data: mockProducts })

      const result = await getProducts('token')

      expect(result).toEqual(mockProducts)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/products')
    })

    it('should handle errors', async () => {
      mockClient.get.mockRejectedValue(new Error('Network error'))

      await expect(getProducts('token')).rejects.toThrow()
    })
  })

  describe('getProduct', () => {
    it('should fetch a single product', async () => {
      const mockProduct = {
        id: 'product1',
        name: 'Test Product',
        price: 100,
        stockLevel: 50,
        unit: 'kg',
      }

      mockClient.get.mockResolvedValue({ data: mockProduct })

      const result = await getProduct('product1', 'token')

      expect(result).toEqual(mockProduct)
      expect(mockClient.get).toHaveBeenCalledWith('/supplier/products/product1')
    })
  })

  describe('createProduct', () => {
    it('should create a new product', async () => {
      const productData = {
        name: 'New Product',
        description: 'Description',
        unit: 'kg',
        price: 100,
        stockLevel: 50,
        minOrderQuantity: 10,
      }

      const mockProduct = { id: 'product1', ...productData }

      mockClient.post.mockResolvedValue({ data: mockProduct })

      const result = await createProduct(productData, 'token')

      expect(result).toEqual(mockProduct)
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/products', productData)
    })
  })

  describe('updateProduct', () => {
    it('should update an existing product', async () => {
      const updateData = { price: 150, stockLevel: 75 }
      const mockProduct = { id: 'product1', name: 'Product', price: 150, stockLevel: 75 }

      mockClient.put.mockResolvedValue({ data: mockProduct })

      const result = await updateProduct('product1', updateData, 'token')

      expect(result).toEqual(mockProduct)
      expect(mockClient.put).toHaveBeenCalledWith('/supplier/products/product1', updateData)
    })
  })

  describe('deleteProduct', () => {
    it('should delete a product', async () => {
      mockClient.delete.mockResolvedValue({ data: {} })

      await deleteProduct('product1', 'token')

      expect(mockClient.delete).toHaveBeenCalledWith('/supplier/products/product1')
    })
  })

  describe('bulkUpdateProducts', () => {
    it('should bulk update products', async () => {
      const bulkData = {
        productIds: ['product1', 'product2'],
        updates: { price: 120 },
      }

      const mockProducts = [
        { id: 'product1', name: 'Product 1', price: 120 },
        { id: 'product2', name: 'Product 2', price: 120 },
      ]

      mockClient.post.mockResolvedValue({ data: mockProducts })

      const result = await bulkUpdateProducts(bulkData, 'token')

      expect(result).toEqual(mockProducts)
      expect(mockClient.post).toHaveBeenCalledWith('/supplier/products/bulk-update', bulkData)
    })
  })
})

