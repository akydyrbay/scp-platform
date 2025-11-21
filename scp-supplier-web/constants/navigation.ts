import type { UserRole } from '@/types/auth'

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
        { label: 'Dashboard', href: '/owner/dashboard', icon: '📊', roles: ['owner'] },
        { label: 'Team Management', href: '/owner/team', icon: '👥', roles: ['owner'] },
        { label: 'Account Settings', href: '/owner/settings', icon: '⚙️', roles: ['owner'] }
      ]
    },
    {
      label: 'Manager Workspace',
      items: [
        { label: 'Dashboard', href: '/manager/dashboard', icon: '📈', roles: ['manager'] },
        { label: 'Catalog Management', href: '/manager/catalog', icon: '🗂️', roles: ['manager'] },
        { label: 'Order Management', href: '/manager/orders', icon: '🧾', roles: ['manager'] },
        { label: 'Complaint Handling', href: '/manager/complaints', icon: '⚠️', roles: ['manager'] }
      ]
    },
    {
      label: 'Sales Workspace',
      items: [
        { label: 'Dashboard', href: '/sales/dashboard', icon: '🧭', roles: ['sales'] },
        { label: 'Consumer Management', href: '/sales/consumers', icon: '🧾', roles: ['sales'] },
        { label: 'Communication Center', href: '/sales/messages', icon: '💬', roles: ['sales'] },
        { label: 'Complaint Handling', href: '/sales/complaints', icon: '🚩', roles: ['sales'] }
      ]
    }
  ]
}


