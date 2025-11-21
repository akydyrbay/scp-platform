import { getClientApiClient } from './client'

export interface SupplierProfile {
  id: string
  name: string
  description?: string | null
  email: string
  phone_number?: string | null
  address?: string | null
  legal_entity?: string | null
  headquarters?: string | null
  registered_address?: string | null
  banking_currency?: string | null
}

export async function getCurrentSupplier (): Promise<SupplierProfile> {
  const client = getClientApiClient()
  const response = await client.get<SupplierProfile>('/supplier/me')
  return response.data
}


