import { getClientApiClient } from './client'
import type { ConsumerLink } from '../types'

export async function getConsumerLinks(token?: string): Promise<ConsumerLink[]> {
  const client = getClientApiClient(token)
  const response = await client.get<ConsumerLink[]>('/supplier/consumer-links')
  return response.data
}

export async function approveConsumerLink(
  linkId: string,
  token?: string
): Promise<ConsumerLink> {
  const client = getClientApiClient(token)
  const response = await client.post<ConsumerLink>(`/supplier/consumer-links/${linkId}/approve`)
  return response.data
}

export async function rejectConsumerLink(
  linkId: string,
  token?: string
): Promise<ConsumerLink> {
  const client = getClientApiClient(token)
  const response = await client.post<ConsumerLink>(`/supplier/consumer-links/${linkId}/reject`)
  return response.data
}

export async function blockConsumer(consumerId: string, token?: string): Promise<void> {
  const client = getClientApiClient(token)
  await client.post(`/supplier/consumers/${consumerId}/block`)
}

export async function unlinkConsumer(consumerId: string, token?: string): Promise<void> {
  const client = getClientApiClient(token)
  await client.post(`/supplier/consumers/${consumerId}/unlink`)
}

