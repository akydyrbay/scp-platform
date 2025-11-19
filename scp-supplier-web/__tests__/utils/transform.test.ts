import { describe, it, expect } from 'vitest'
import { transformUser } from '../../lib/utils/transform'

describe('Transform Utilities', () => {
  describe('transformUser', () => {
    it('should transform snake_case user to include both formats', () => {
      const userData = {
        id: 'user1',
        email: 'test@example.com',
        role: 'owner',
        first_name: 'John',
        last_name: 'Doe',
        company_name: 'Test Company',
        phone_number: '1234567890',
        profile_image_url: 'https://example.com/image.jpg',
        supplier_id: 'supplier1',
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-02T00:00:00Z',
      }

      const result = transformUser(userData)

      // Should keep snake_case
      expect(result.first_name).toBe('John')
      expect(result.last_name).toBe('Doe')
      expect(result.company_name).toBe('Test Company')
      expect(result.phone_number).toBe('1234567890')
      expect(result.profile_image_url).toBe('https://example.com/image.jpg')
      expect(result.supplier_id).toBe('supplier1')
      expect(result.created_at).toBe('2024-01-01T00:00:00Z')
      expect(result.updated_at).toBe('2024-01-02T00:00:00Z')

      // Should also provide camelCase
      expect(result.firstName).toBe('John')
      expect(result.lastName).toBe('Doe')
      expect(result.companyName).toBe('Test Company')
      expect(result.phoneNumber).toBe('1234567890')
      expect(result.profileImageUrl).toBe('https://example.com/image.jpg')
      expect(result.createdAt).toBe('2024-01-01T00:00:00Z')
      expect(result.updatedAt).toBe('2024-01-02T00:00:00Z')
    })

    it('should handle camelCase input and add snake_case', () => {
      const userData = {
        id: 'user1',
        email: 'test@example.com',
        role: 'manager',
        firstName: 'Jane',
        lastName: 'Smith',
        companyName: 'Company',
      }

      const result = transformUser(userData)

      expect(result.firstName).toBe('Jane')
      expect(result.first_name).toBe('Jane')
      expect(result.lastName).toBe('Smith')
      expect(result.last_name).toBe('Smith')
      expect(result.companyName).toBe('Company')
      expect(result.company_name).toBe('Company')
    })

    it('should handle missing fields gracefully', () => {
      const userData = {
        id: 'user1',
        email: 'test@example.com',
        role: 'sales_rep',
      }

      const result = transformUser(userData)

      expect(result.id).toBe('user1')
      expect(result.email).toBe('test@example.com')
      expect(result.role).toBe('sales_rep')
      expect(result.firstName).toBeUndefined()
      expect(result.first_name).toBeUndefined()
    })

    it('should prioritize snake_case over camelCase if both exist', () => {
      const userData = {
        id: 'user1',
        email: 'test@example.com',
        role: 'owner',
        first_name: 'Snake',
        firstName: 'Camel',
      }

      const result = transformUser(userData)

      expect(result.first_name).toBe('Snake')
      expect(result.firstName).toBe('Snake') // Should use snake_case value
    })
  })
})

