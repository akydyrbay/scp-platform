import { getClientApiClient } from './client'

export interface Product {
  id: string
  name: string
  description?: string | null
  image_url?: string | null
  unit: string
  price: number
  discount?: number | null
  stock_level: number
  min_order_quantity: number
  supplier_id: string
  category?: string | null
  created_at: string
  updated_at?: string | null
}

export interface PaginatedProducts {
  results: Product[]
  pagination: {
    page: number
    page_size: number
    total: number
    total_pages: number
  }
}

export interface CreateProductRequest {
  name: string
  description?: string
  image_url?: string
  unit: string
  price: number
  discount?: number
  stock_level: number
  min_order_quantity: number
  category?: string
}

export interface UpdateProductRequest {
  name?: string
  description?: string
  image_url?: string
  unit?: string
  price?: number
  discount?: number | null
  stock_level?: number
  min_order_quantity?: number
  category?: string
}

export async function getProducts(page = 1, pageSize = 20): Promise<PaginatedProducts> {
  const client = getClientApiClient()
  
  try {
    const response = await client.get<PaginatedProducts>('/supplier/products', {
      params: { page, page_size: pageSize },
    })
    
    console.log('[Products API] Raw response:', {
      status: response.status,
      hasData: !!response.data,
      dataKeys: response.data ? Object.keys(response.data) : [],
      dataType: typeof response.data,
      dataPreview: JSON.stringify(response.data).substring(0, 500)
    })
    
    // Handle different response formats
    if (response.data && 'results' in response.data) {
      // Ensure results is always an array
      const results = Array.isArray(response.data.results) ? response.data.results : []
      console.log('[Products API] Parsed results:', {
        count: results.length,
        sample: results.slice(0, 2).map(p => ({
          id: p.id,
          name: p.name,
          category: p.category,
          hasCategory: !!p.category
        }))
      })
      return {
        results,
        pagination: response.data.pagination || {
          page,
          page_size: pageSize,
          total: 0,
          total_pages: 0,
        },
      }
    }
    
    // If response format is different (wrapped in success/data)
    if (response.data && 'success' in response.data && (response.data as any).success) {
      const data = (response.data as any).data
      if (data && 'results' in data) {
        const results = Array.isArray(data.results) ? data.results : []
        console.log('[Products API] Parsed wrapped results:', {
          count: results.length,
          sample: results.slice(0, 2)
        })
        return {
          results,
          pagination: data.pagination || {
            page,
            page_size: pageSize,
            total: 0,
            total_pages: 0,
          },
        }
      }
    }
    
    // Check if response.data is directly an array (some APIs return array directly)
    if (Array.isArray(response.data)) {
      const dataArray = response.data as Product[]
      console.log('[Products API] Response is direct array:', {
        count: dataArray.length,
        sample: dataArray.slice(0, 2)
      })
      return {
        results: dataArray,
        pagination: {
          page,
          page_size: pageSize,
          total: dataArray.length,
          total_pages: 1,
        },
      }
    }
    
    // Return empty paginated response if format is unexpected
    console.warn('[Products API] Unexpected response format:', response.data)
    return {
      results: [],
      pagination: {
        page,
        page_size: pageSize,
        total: 0,
        total_pages: 0,
      },
    }
  } catch (error: any) {
    // Handle 500 errors gracefully
    if (error.response?.status === 500) {
      const errorMessage = error.response?.data?.error?.message || 'Server error occurred'
      console.error('Products API error:', errorMessage)
    } else {
      console.error('Failed to fetch products:', error)
    }
    
    // Return empty paginated response instead of throwing
    return {
      results: [],
      pagination: {
        page,
        page_size: pageSize,
        total: 0,
        total_pages: 0,
      },
    }
  }
}

export async function getProduct(id: string): Promise<Product> {
  const client = getClientApiClient()
  
  // Log the API call for debugging
  const apiUrl = `/supplier/products/${id}`
  console.log('[getProduct] API call to:', apiUrl)
  console.log('[getProduct] Product ID being requested:', id)
  
  try {
    if (!id || id.trim() === '') {
      throw new Error('Product ID is required')
    }

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    if (!uuidRegex.test(id)) {
      throw new Error(`Invalid product ID format: ${id}`)
    }

    const response = await client.get<Product | { success: boolean; data: Product }>(apiUrl)
    
    console.log('[getProduct] API response:', {
      status: response.status,
      hasData: !!response.data,
      dataType: typeof response.data,
      dataKeys: response.data ? Object.keys(response.data) : [],
      dataPreview: response.data ? JSON.stringify(response.data).substring(0, 200) : 'no data'
    })
    
    // Handle different response formats
    if (response.data && typeof response.data === 'object') {
      // Direct product format - check for required fields
      if ('id' in response.data && 'name' in response.data && 'price' in response.data) {
        const product = response.data as Product
        console.log('[getProduct] Product fetched successfully (direct format):', product.id)
        return product
      }
      
      // Wrapped format (success/data)
      if ('success' in response.data && 'data' in response.data) {
        const wrappedData = (response.data as any).data
        if (wrappedData && 'id' in wrappedData && 'name' in wrappedData && 'price' in wrappedData) {
          console.log('[getProduct] Product fetched successfully (wrapped format):', wrappedData.id)
          return wrappedData as Product
        }
      }
      
      // Try to extract product from error response format
      if ('error' in response.data) {
        const errorData = (response.data as any).error
        if (errorData && typeof errorData === 'object' && 'message' in errorData) {
          throw new Error(errorData.message || 'Failed to fetch product')
        }
      }
    }
    
    console.error('[getProduct] Unexpected response format:', {
      data: response.data,
      dataType: typeof response.data,
      isArray: Array.isArray(response.data),
      keys: response.data ? Object.keys(response.data) : []
    })
    throw new Error('Invalid product response format from server')
  } catch (error: any) {
    // Handle JSON parse errors specifically
    if (error.message?.includes('JSON') || error.message?.includes('Unexpected') || error.message?.includes('Invalid JSON')) {
      console.error('JSON parse error in getProduct:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        url: apiUrl
      })
      
      // Check if response is HTML
      if (error.response?.data && typeof error.response.data === 'string') {
        if (error.response.data.includes('<!DOCTYPE') || error.response.data.includes('<html')) {
          throw new Error('Server returned an error page. Please check if the backend API is running correctly.')
        }
      }
      
      throw new Error(`Invalid JSON response from server: ${error.message}. Please check if the backend API is running correctly.`)
    }
    // Handle network errors
    if (error.code === 'ECONNREFUSED' || error.code === 'ERR_NETWORK' || error.message?.includes('Network Error')) {
      throw new Error('Cannot connect to server. Please check if the backend API is running.')
    }
    
    // Handle timeout errors
    if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      throw new Error('Request timeout. Please try again later.')
    }
    
    // Handle HTTP errors
    if (error.response) {
      const status = error.response.status
      const errorData = error.response.data
      const errorMessage = errorData?.error?.message || errorData?.message || 'Unknown error'
      const requestUrl = error.config?.url || apiUrl
      const requestMethod = error.config?.method?.toUpperCase() || 'GET'
      
      // Log detailed error information for debugging
      // Ensure we log actual values, not undefined/null
      const logData: Record<string, any> = {
        status: status || 'unknown',
        url: requestUrl || apiUrl,
        method: requestMethod,
        productId: id || 'unknown',
      }
      
      // Only add errorData if it exists and has content
      if (errorData && typeof errorData === 'object' && Object.keys(errorData).length > 0) {
        logData.errorData = errorData
      } else if (typeof errorData === 'string' && errorData.trim()) {
        logData.errorData = errorData
      }
      
      // Only add errorMessage if it exists and is different from default
      if (errorMessage && errorMessage !== 'Unknown error') {
        logData.errorMessage = errorMessage
      }
      
      // Log the actual error object for full context
      console.error('[getProduct] API Error Details:', logData)
      console.error('[getProduct] Full error object:', {
        message: error.message,
        code: error.code,
        response: {
          status: error.response.status,
          statusText: error.response.statusText,
          headers: error.response.headers,
          data: error.response.data,
        },
        request: {
          url: error.config?.url,
          method: error.config?.method,
          headers: error.config?.headers,
        },
      })
      
      if (status === 404) {
        // Fallback: Try to get product from list if single product endpoint doesn't exist
        console.log('[getProduct] 404 error, trying fallback: fetch from products list')
        try {
          const allProducts = await getProducts(1, 1000) // Get large page to find the product
          const product = allProducts.results.find(p => p.id === id)
          if (product) {
            console.log('[getProduct] Product found via fallback method:', product.id)
            return product
          }
        } catch (fallbackError) {
          console.error('[getProduct] Fallback method also failed:', fallbackError)
          // Continue to throw original 404 error
        }
        throw new Error(`Product not found (ID: ${id}). It may have been deleted or does not exist.`)
      }
      if (status === 403) {
        throw new Error('You do not have permission to access this product. It may belong to a different supplier.')
      }
      if (status === 400) {
        throw new Error(errorMessage || 'Invalid request. Please check the product ID.')
      }
      if (status === 500) {
        throw new Error('Server error occurred. Please try again later.')
      }
      
      throw new Error(errorMessage || `Failed to fetch product (${status})`)
    }
    
    // Handle other errors (non-HTTP errors)
    throw new Error(error.message || 'Failed to fetch product. Please try again.')
  }
}

export async function createProduct(data: CreateProductRequest): Promise<Product> {
  const client = getClientApiClient()
  
  try {
    const response = await client.post<Product>('/supplier/products', data)
    
    // Handle different response formats
    if (response.data && 'id' in response.data) {
      return response.data
    }
    
    // If response is wrapped in success/data
    if (response.data && 'success' in response.data && (response.data as any).success) {
      const product = (response.data as any).data
      if (product && 'id' in product) {
        return product
      }
    }
    
    throw new Error('Invalid product response format')
  } catch (error: any) {
    if (error.response?.status === 400) {
      const message = error.response?.data?.error?.message || 'Invalid product data'
      throw new Error(message)
    }
    if (error.response?.status === 500) {
      const message = error.response?.data?.error?.message || 'Server error occurred'
      throw new Error(message)
    }
    throw new Error(error.response?.data?.error?.message || error.message || 'Failed to create product')
  }
}

export async function updateProduct(id: string, data: UpdateProductRequest): Promise<Product> {
  const client = getClientApiClient()
  
  try {
    const response = await client.put<Product>(`/supplier/products/${id}`, data)
    
    // Handle different response formats
    if (response.data && 'id' in response.data) {
      return response.data
    }
    
    // If response is wrapped in success/data
    if (response.data && 'success' in response.data && (response.data as any).success) {
      const product = (response.data as any).data
      if (product && 'id' in product) {
        return product
      }
    }
    
    throw new Error('Invalid product response format')
  } catch (error: any) {
    if (error.response?.status === 400) {
      const message = error.response?.data?.error?.message || 'Invalid product data'
      throw new Error(message)
    }
    if (error.response?.status === 404) {
      throw new Error('Product not found')
    }
    if (error.response?.status === 500) {
      const message = error.response?.data?.error?.message || 'Server error occurred'
      throw new Error(message)
    }
    throw new Error(error.response?.data?.error?.message || error.message || 'Failed to update product')
  }
}

export async function deleteProduct(id: string): Promise<void> {
  const client = getClientApiClient()
  const apiUrl = `/supplier/products/${id}`
  
  try {
    if (!id || id.trim() === '') {
      throw new Error('Product ID is required')
    }

    await client.delete(apiUrl)
  } catch (error: any) {
    // Handle network errors
    if (error.code === 'ECONNREFUSED' || error.code === 'ERR_NETWORK' || error.message?.includes('Network Error')) {
      throw new Error('Cannot connect to server. Please check if the backend API is running.')
    }
    
    // Handle timeout errors
    if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      throw new Error('Request timeout. Please try again later.')
    }
    
    // Handle HTTP errors
    if (error.response) {
      const status = error.response.status
      const errorData = error.response.data
      const errorMessage = errorData?.error?.message || errorData?.message || 'Unknown error'
      
      if (status === 404) {
        throw new Error(`Product not found (ID: ${id}). It may have already been deleted.`)
      }
      if (status === 403) {
        throw new Error('You do not have permission to delete this product. It may belong to a different supplier.')
      }
      if (status === 400) {
        throw new Error(errorMessage || 'Invalid request. Please check the product ID.')
      }
      if (status === 500) {
        throw new Error('Server error occurred while deleting the product. Please try again later.')
      }
      
      throw new Error(errorMessage || `Failed to delete product (${status})`)
    }
    
    // Handle other errors
    throw new Error(error.message || 'Failed to delete product. Please try again.')
  }
}

