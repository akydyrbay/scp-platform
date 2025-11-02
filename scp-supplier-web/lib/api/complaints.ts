import { getClientApiClient } from './client'
import type { Complaint } from '../types'

export async function getComplaints(token?: string): Promise<Complaint[]> {
  const client = getClientApiClient(token)
  const response = await client.get<Complaint[]>('/supplier/complaints')
  return response.data
}

export async function getComplaint(complaintId: string, token?: string): Promise<Complaint> {
  const client = getClientApiClient(token)
  const response = await client.get<Complaint>(`/supplier/complaints/${complaintId}`)
  return response.data
}

export interface ResolveComplaintData {
  resolution: string
}

export async function resolveComplaint(
  complaintId: string,
  data: ResolveComplaintData,
  token?: string
): Promise<Complaint> {
  const client = getClientApiClient(token)
  const response = await client.post<Complaint>(`/supplier/complaints/${complaintId}/resolve`, data)
  return response.data
}

