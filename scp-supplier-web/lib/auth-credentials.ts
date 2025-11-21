import type { SessionUser, UserRole } from '@/types/auth'

interface AccountRecord {
  password: string
  role: UserRole
  name: string
}

const accounts: Record<string, AccountRecord> = {
  '1@gmail.com': {
    password: '12345',
    role: 'owner',
    name: 'Owner Executive'
  },
  '2@gmail.com': {
    password: '12345',
    role: 'manager',
    name: 'Manager Lead'
  }
}

export function verifyCredentials (email: string, password: string): SessionUser | null {
  const record = accounts[email.toLowerCase()]
  if (!record) return null
  if (record.password !== password) return null

  return {
    id: `${record.role}-${email}`,
    name: record.name,
    email,
    role: record.role
  }
}

