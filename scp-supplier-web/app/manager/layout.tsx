'use client'

import type { ReactNode } from 'react'
import { AuthGuard } from '@/lib/auth-guard'
import { RoleSidebarNav, type SidebarItem } from '@/components/navigation/role-sidebar-nav'
import { useAuthStore } from '@/lib/store/auth-store'

const navItems: SidebarItem[] = [
  { href: '/manager/dashboard', label: 'Dashboard', icon: 'package' },
  { href: '/manager/catalog', label: 'Catalog Management', icon: 'catalog' },
  { href: '/manager/orders', label: 'Order Management', icon: 'orders' },
  { href: '/manager/complaints', label: 'Complaint Handling', icon: 'complaints' },
  { href: '/manager/links', label: 'Consumer Links', icon: 'team' },
  { href: '/manager/settings', label: 'Manager User', icon: 'settings' }
]

export default function ManagerLayout({ children }: { children: ReactNode }) {
  const { user } = useAuthStore()

  return (
    <AuthGuard allowedRoles={['manager']}>
      <div className='relative min-h-screen bg-[#F7F9FB]'>
        <aside className='fixed left-10 top-10 h-[904px] w-[269px] rounded-3xl border border-[#E3E8EF] bg-[#F7F9FB] shadow-[0_40px_80px_rgba(15,23,42,0.05)]'>
          <div className='flex h-full flex-col gap-10 px-8 py-10'>
            <div>
              <p className='text-xs uppercase tracking-[0.4em] text-neutral-500'>Supplier Platform</p>
              <h1 className='mt-3 text-2xl font-semibold text-neutral-900'>{user?.name || 'Manager'}</h1>
              <p className='text-sm text-neutral-500'>{user?.email || ''}</p>
            </div>

            <RoleSidebarNav items={navItems} />
          </div>
        </aside>

        <main className='ml-[329px] flex min-h-screen justify-center px-10 py-10'>
          {children}
        </main>
      </div>
    </AuthGuard>
  )
}


