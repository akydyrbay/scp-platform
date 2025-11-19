export type UserRole = 'owner' | 'manager' | 'sales_rep' | 'sales'

export interface User {
  id: string
  email: string
  first_name?: string
  last_name?: string
  company_name?: string
  phone_number?: string
  role: UserRole
  profile_image_url?: string
  supplier_id?: string
  created_at: string
  updated_at?: string
  // Frontend convenience properties (transformed from snake_case)
  firstName?: string
  lastName?: string
  companyName?: string
  phoneNumber?: string
  profileImageUrl?: string
  createdAt?: string
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
  total_orders: number
  pending_orders: number
  pending_link_requests: number
  low_stock_items: number
  recent_orders: Order[]
  low_stock_products: Product[]
  // Frontend convenience properties (transformed from snake_case)
  totalOrders?: number
  pendingOrders?: number
  pendingLinkRequests?: number
  lowStockItems?: number
  recentOrders?: Order[]
  lowStockProducts?: Product[]
}

