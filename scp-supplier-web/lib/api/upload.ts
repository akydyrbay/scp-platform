import { getClientApiClient } from './client'

export async function uploadFile(file: File): Promise<string> {
  const client = getClientApiClient()
  
  const formData = new FormData()
  formData.append('file', file)

  try {
    const response = await client.post<{ success: boolean; data: { url: string } }>('/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })

    if (response.data.success && response.data.data?.url) {
      // Return full URL if not already absolute
      const url = response.data.data.url
      if (url.startsWith('http')) {
        return url
      }
      const baseURL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000/api/v1'
      const apiBase = baseURL.replace('/api/v1', '')
      return `${apiBase}${url}`
    }

    throw new Error('Invalid upload response')
  } catch (error: any) {
    if (error.response?.status === 400) {
      const message = error.response?.data?.error?.message || 'File upload failed'
      throw new Error(message)
    }
    if (error.response?.status === 413) {
      throw new Error('File size exceeds 10MB limit')
    }
    throw new Error(error.response?.data?.error?.message || 'Failed to upload file')
  }
}

