import { getClientApiClient } from './client'
import type { DashboardStats } from '../types'

export async function getDashboardStats(token?: string): Promise<DashboardStats> {
  const client = getClientApiClient(token)
  const response = await client.get<DashboardStats>('/supplier/dashboard/stats')
  return response.data
}

