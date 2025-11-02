export type UserRole = 'owner' | 'manager' | 'sales_rep'

export interface User {
  id: string
  email: string
  firstName?: string
  lastName?: string
  companyName?: string
  phoneNumber?: string
  role: UserRole
  profileImageUrl?: string
  createdAt: string
  updatedAt?: string
}

export interface Product {
  id: string
  name: string
  description?: string
  imageUrl?: string
  unit: string
  price: number
  discount?: number
  stockLevel: number
  minOrderQuantity: number
  supplierId: string
  createdAt: string
  updatedAt?: string
}

export interface Order {
  id: string
  consumerId: string
  consumerName?: string
  supplierId: string
  status: 'pending' | 'accepted' | 'rejected' | 'completed' | 'cancelled'
  subtotal: number
  tax: number
  shippingFee: number
  total: number
  items: OrderItem[]
  createdAt: string
  updatedAt?: string
}

export interface OrderItem {
  id: string
  orderId: string
  productId: string
  productName?: string
  quantity: number
  unitPrice: number
  subtotal: number
}

export interface ConsumerLink {
  id: string
  consumerId: string
  consumerName?: string
  consumerEmail?: string
  status: 'pending' | 'approved' | 'rejected' | 'blocked'
  requestedAt: string
  approvedAt?: string
}

export interface Complaint {
  id: string
  conversationId: string
  consumerId: string
  consumerName?: string
  orderId?: string
  title: string
  description: string
  priority: 'low' | 'medium' | 'high' | 'urgent'
  status: 'open' | 'in_progress' | 'resolved' | 'escalated'
  escalatedBy?: string
  escalatedAt?: string
  resolvedAt?: string
  createdAt: string
}

export interface DashboardStats {
  totalOrders: number
  pendingOrders: number
  pendingLinkRequests: number
  lowStockItems: number
  recentOrders: Order[]
  lowStockProducts: Product[]
}

