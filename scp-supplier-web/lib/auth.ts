import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { randomUUID } from 'node:crypto'

import type { Session, UserRole } from '@/types/auth'

const SESSION_COOKIE = 'supplier-platform-session'

const roleRedirectMap: Record<UserRole, string> = {
  owner: '/owner/dashboard',
  manager: '/manager/dashboard',
  sales: '/sales/dashboard'
}

export async function getSession (): Promise<Session | null> {
  const store = await cookies()
  const serialized = store.get(SESSION_COOKIE)?.value

  if (!serialized) return null

  try {
    const session = JSON.parse(serialized) as Session
    return session
  } catch (error) {
    console.error('Invalid session payload', error)
    store.delete(SESSION_COOKIE)
    return null
  }
}

export async function requireRole (allowed: UserRole[]): Promise<Session> {
  const session = await getSession()

  if (!session) redirect('/login')
  if (!allowed.includes(session.user.role)) redirect(roleRedirectMap[session.user.role])

  return session
}

export async function createSession (role: UserRole) {
  const store = await cookies()
  const payload: Session = {
    user: {
      id: randomUUID(),
      name: `${role.charAt(0).toUpperCase()}${role.slice(1)} User`,
      email: `${role}@supplier-platform.com`,
      role
    },
    issuedAt: new Date().toISOString()
  }

  store.set(SESSION_COOKIE, JSON.stringify(payload), {
    httpOnly: true,
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 12
  })
}

export async function clearSession () {
  const store = await cookies()
  store.delete(SESSION_COOKIE)
}

export function resolveRoleDestination (role: UserRole): string {
  return roleRedirectMap[role]
}


