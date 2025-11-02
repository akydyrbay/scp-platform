import { getClientApiClient } from './client'
import type { User } from '../types'

export interface CreateUserData {
  email: string
  password: string
  firstName: string
  lastName: string
  role: 'manager' | 'sales_rep'
}

export async function getUsers(token?: string): Promise<User[]> {
  const client = getClientApiClient(token)
  const response = await client.get<User[]>('/supplier/users')
  return response.data
}

export async function createUser(data: CreateUserData, token?: string): Promise<User> {
  const client = getClientApiClient(token)
  const response = await client.post<User>('/supplier/users', data)
  return response.data
}

export async function deleteUser(userId: string, token?: string): Promise<void> {
  const client = getClientApiClient(token)
  await client.delete(`/supplier/users/${userId}`)
}

