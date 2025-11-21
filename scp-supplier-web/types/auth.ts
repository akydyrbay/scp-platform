export type UserRole = 'owner' | 'manager' | 'sales'

export interface SessionUser {
  id: string
  name: string
  email: string
  role: UserRole
  company_name?: string | null
  supplier_id?: string | null
}

export interface Session {
  user: SessionUser
  issuedAt: string
}


