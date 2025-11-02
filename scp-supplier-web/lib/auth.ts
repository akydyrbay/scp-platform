import { cookies } from 'next/headers'
import { getServerApiClient } from './api/client'
import type { User } from './types'

export interface Session {
  user: User | null
  token: string | null
}

export async function getServerSession(): Promise<Session | null> {
  try {
    const cookieStore = cookies()
    const token = cookieStore.get('auth_token')?.value

    if (!token) {
      return null
    }

    try {
      const client = getServerApiClient(token)
      const response = await client.get<{ user: User }>('/auth/me')
      return {
        user: response.data.user,
        token,
      }
    } catch (error) {
      return null
    }
  } catch (error) {
    return null
  }
}

export function requireAuth(role?: 'owner' | 'manager'): {
  redirect: { destination: string; permanent: boolean }
} | null {
  // This will be used in middleware
  return null
}

