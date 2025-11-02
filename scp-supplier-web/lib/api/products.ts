import { getClientApiClient } from './client'
import type { Product } from '../types'

export interface CreateProductData {
  name: string
  description?: string
  imageUrl?: string
  unit: string
  price: number
  discount?: number
  stockLevel: number
  minOrderQuantity: number
}

export interface UpdateProductData extends Partial<CreateProductData> {}

export interface BulkUpdateData {
  productIds: string[]
  updates: {
    price?: number
    stockLevel?: number
    discount?: number
  }
}

export async function getProducts(token?: string): Promise<Product[]> {
  const client = getClientApiClient(token)
  const response = await client.get<Product[]>('/supplier/products')
  return response.data
}

export async function getProduct(productId: string, token?: string): Promise<Product> {
  const client = getClientApiClient(token)
  const response = await client.get<Product>(`/supplier/products/${productId}`)
  return response.data
}

export async function createProduct(data: CreateProductData, token?: string): Promise<Product> {
  const client = getClientApiClient(token)
  const response = await client.post<Product>('/supplier/products', data)
  return response.data
}

export async function updateProduct(
  productId: string,
  data: UpdateProductData,
  token?: string
): Promise<Product> {
  const client = getClientApiClient(token)
  const response = await client.put<Product>(`/supplier/products/${productId}`, data)
  return response.data
}

export async function deleteProduct(productId: string, token?: string): Promise<void> {
  const client = getClientApiClient(token)
  await client.delete(`/supplier/products/${productId}`)
}

export async function bulkUpdateProducts(
  data: BulkUpdateData,
  token?: string
): Promise<Product[]> {
  const client = getClientApiClient(token)
  const response = await client.post<Product[]>('/supplier/products/bulk-update', data)
  return response.data
}

