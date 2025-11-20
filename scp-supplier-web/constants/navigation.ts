import type { UserRole } from '@/lib/types'

export interface SidebarItem {
  label: string
  href: string
  icon: string
  roles: UserRole[]
}

export interface SidebarSection {
  label: string
  items: SidebarItem[]
}

interface SidebarConfig {
  sections: SidebarSection[]
}

export const sidebarConfig: SidebarConfig = {
  sections: [
    {
      label: 'Owner Workspace',
      items: [
        { label: 'Dashboard', href: '/owner/dashboard', icon: 'dashboard', roles: ['owner'] },
        { label: 'Team Management', href: '/users', icon: 'team', roles: ['owner'] }
      ]
    },
    {
      label: 'Manager Workspace',
      items: [
        { label: 'Dashboard', href: '/manager/dashboard', icon: 'dashboard', roles: ['manager'] },
        { label: 'Catalog Management', href: '/manager/catalog', icon: 'catalog', roles: ['manager'] },
        { label: 'Order Management', href: '/manager/orders', icon: 'orders', roles: ['manager'] },
        { label: 'Complaints', href: '/incidents', icon: 'complaints', roles: ['manager'] }
      ]
    },
    {
      label: 'Sales Workspace',
      items: [
        { label: 'Dashboard', href: '/dashboard', icon: 'dashboard', roles: ['sales', 'sales_rep'] },
        { label: 'Consumer Management', href: '/consumers', icon: 'team', roles: ['sales', 'sales_rep'] },
        { label: 'Complaints', href: '/incidents', icon: 'complaints', roles: ['sales', 'sales_rep'] }
      ]
    }
  ]
}

