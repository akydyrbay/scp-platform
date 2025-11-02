import { getClientApiClient } from './client'
import type { Order } from '../types'

export async function getOrders(token?: string): Promise<Order[]> {
  const client = getClientApiClient(token)
  const response = await client.get<Order[]>('/supplier/orders')
  return response.data
}

export async function getOrder(orderId: string, token?: string): Promise<Order> {
  const client = getClientApiClient(token)
  const response = await client.get<Order>(`/supplier/orders/${orderId}`)
  return response.data
}

export async function acceptOrder(orderId: string, token?: string): Promise<Order> {
  const client = getClientApiClient(token)
  const response = await client.post<Order>(`/supplier/orders/${orderId}/accept`)
  return response.data
}

export async function rejectOrder(orderId: string, token?: string): Promise<Order> {
  const client = getClientApiClient(token)
  const response = await client.post<Order>(`/supplier/orders/${orderId}/reject`)
  return response.data
}

