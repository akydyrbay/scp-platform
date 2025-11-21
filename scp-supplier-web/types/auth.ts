export type UserRole = 'owner' | 'manager' | 'sales'

export interface SessionUser {
  id: string
  name: string
  email: string
  role: UserRole
}

export interface Session {
  user: SessionUser
  issuedAt: string
}


