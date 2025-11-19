import type { User } from '../types'

export function transformUser(user: any): User {
  return {
    ...user,
    // Keep snake_case for compatibility with backend
    first_name: user.first_name || user.firstName,
    last_name: user.last_name || user.lastName,
    company_name: user.company_name || user.companyName,
    phone_number: user.phone_number || user.phoneNumber,
    profile_image_url: user.profile_image_url || user.profileImageUrl,
    supplier_id: user.supplier_id || user.supplierId,
    created_at: user.created_at || user.createdAt,
    updated_at: user.updated_at || user.updatedAt,
    // Also provide camelCase for frontend convenience
    firstName: user.first_name || user.firstName,
    lastName: user.last_name || user.lastName,
    companyName: user.company_name || user.companyName,
    phoneNumber: user.phone_number || user.phoneNumber,
    profileImageUrl: user.profile_image_url || user.profileImageUrl,
    createdAt: user.created_at || user.createdAt,
    updatedAt: user.updated_at || user.updatedAt,
  }
}

