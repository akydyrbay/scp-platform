import { getClientApiClient } from './client'
import type { ConsumerLink } from '../types'

export async function getConsumerLinks(token?: string): Promise<ConsumerLink[]> {
  const client = getClientApiClient(token)
  // Backend returns paginated response: { results: [...], pagination: {...} }
  const response = await client.get<{ results: ConsumerLink[]; pagination: any }>('/supplier/consumer-links')
  return response.data.results || []
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

export async function blockConsumerLink(linkId: string, token?: string): Promise<ConsumerLink> {
  const client = getClientApiClient(token)
  const response = await client.post<ConsumerLink>(`/supplier/consumer-links/${linkId}/block`)
  return response.data
}

