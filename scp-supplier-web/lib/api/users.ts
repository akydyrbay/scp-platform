import { getClientApiClient } from './client'

export interface User {
  id: string
  email: string
  first_name?: string | null
  last_name?: string | null
  company_name?: string | null
  phone_number?: string | null
  role: string
  profile_image_url?: string | null
  supplier_id?: string | null
  created_at: string
  updated_at?: string | null
}

export interface CreateUserRequest {
  email: string
  password: string
  first_name?: string
  last_name?: string
  company_name?: string
  role: 'owner' | 'manager' | 'sales_rep'
  supplier_id?: string
}

export async function getUsers(): Promise<User[]> {
  const client = getClientApiClient()
  
  try {
    console.log('Fetching users from API: /supplier/users')
    const response = await client.get<User[]>('/supplier/users')
    
    console.log('GetUsers API response:', {
      status: response.status,
      dataType: Array.isArray(response.data) ? 'array' : typeof response.data,
      dataLength: Array.isArray(response.data) ? response.data.length : 'N/A',
      rawData: response.data
    })
    
    // Handle different response formats
    if (Array.isArray(response.data)) {
      console.log(`Found ${response.data.length} total users from API`)
      
      // Filter out owner users - only show manager and sales_rep
      const filteredUsers = response.data.filter(user => {
        const isManagerOrSalesRep = user.role === 'manager' || user.role === 'sales_rep'
        if (!isManagerOrSalesRep) {
          console.log(`Filtering out user with role: ${user.role}`, user)
        }
        return isManagerOrSalesRep
      })
      
      console.log(`Filtered to ${filteredUsers.length} non-owner users (manager/sales_rep)`)
      console.log('Filtered users:', filteredUsers.map(u => ({ id: u.id, email: u.email, role: u.role })))
      
      return filteredUsers
    }
    
    // If response is wrapped in success/data
    if (response.data && typeof response.data === 'object' && 'success' in response.data) {
      const data = (response.data as any).data
      if (Array.isArray(data)) {
        console.log(`Found ${data.length} users in wrapped response`)
        // Filter out owner users
        const filteredUsers = data.filter((user: User) => {
          const isManagerOrSalesRep = user.role === 'manager' || user.role === 'sales_rep'
          return isManagerOrSalesRep
        })
        console.log(`Filtered to ${filteredUsers.length} non-owner users`)
        return filteredUsers
      }
    }
    
    // Return empty array if format is unexpected
    console.warn('Unexpected response format from GetUsers API:', response.data)
    return []
  } catch (error: any) {
    console.error('Failed to fetch users:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      fullError: error
    })
    
    // Handle network errors
    if (error.code === 'ECONNREFUSED' || error.code === 'ERR_NETWORK') {
      console.error('Network error: Cannot connect to server')
      throw new Error('Cannot connect to server. Please check if the backend API is running.')
    }
    
    // Return empty array instead of throwing to prevent UI errors
    // But log the error for debugging
    return []
  }
}

export async function createUser(data: CreateUserRequest): Promise<User> {
  const client = getClientApiClient()
  
  try {
    console.log('Creating user with data:', data)
    const response = await client.post<User>('/supplier/users', data)
    
    console.log('CreateUser API response:', {
      status: response.status,
      data: response.data,
      dataType: typeof response.data
    })
    
    // Handle different response formats
    if (response.data && 'id' in response.data) {
      console.log('User created successfully:', response.data.id)
      return response.data
    }
    
    // If response is wrapped in success/data
    if (response.data && typeof response.data === 'object' && 'success' in response.data) {
      const wrappedData = (response.data as any).data
      if (wrappedData && 'id' in wrappedData) {
        console.log('User created successfully (wrapped format):', wrappedData.id)
        return wrappedData
      }
    }
    
    throw new Error('Invalid response format from create user API')
  } catch (error: any) {
    console.error('Failed to create user:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data,
      fullError: error
    })
    
    // Handle network errors
    if (error.code === 'ECONNREFUSED' || error.code === 'ERR_NETWORK') {
      throw new Error('Cannot connect to server. Please check if the backend API is running.')
    }
    
    // Handle HTTP errors
    if (error.response) {
      const status = error.response.status
      const errorData = error.response.data
      const errorMessage = errorData?.error?.message || errorData?.message || 'Failed to create user'
      
      if (status === 400) {
        throw new Error(errorMessage || 'Invalid request data')
      }
      if (status === 409) {
        throw new Error(errorMessage || 'User already exists')
      }
      if (status === 500) {
        throw new Error(errorMessage || 'Server error occurred')
      }
      
      throw new Error(errorMessage || `Failed to create user (${status})`)
    }
    
    throw new Error(error.message || 'Failed to create user. Please try again.')
  }
}

export async function deleteUser(id: string): Promise<void> {
  const client = getClientApiClient()
  await client.delete(`/supplier/users/${id}`)
}

