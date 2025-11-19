'use client'

import { Suspense, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

import type { UserRole } from '@/lib/types'
import { useAuthStore } from '@/lib/store/auth-store'
import { sidebarConfig, type SidebarSection } from '@/constants/navigation'
import { UserAvatar } from '@/components/navigation/user-avatar'
import { SidebarToggle } from '@/components/navigation/sidebar-toggle'
import { SidebarLink } from '@/components/navigation/sidebar-link'
import styles from './dashboard-shell.module.styl'

interface DashboardShellProps {
  role: UserRole
  children: React.ReactNode
}

function resolveRoleDestination (role: UserRole): string {
  const map: Record<UserRole, string> = {
    owner: '/owner/dashboard',
    manager: '/manager/dashboard',
    sales_rep: '/sales/dashboard',
    sales: '/sales/dashboard'
  }
  return map[role] || '/dashboard'
}

function renderSection (section: SidebarSection, role: UserRole) {
  const iconMap: Record<string, string> = {
    dashboard: '📊',
    team: '👥',
    settings: '⚙️',
    catalog: '🗂️',
    orders: '🧾',
    complaints: '⚠️'
  }

  return (
    <div key={section.label} className={styles.sidebarSection}>
      <p className={styles.sidebarSectionLabel}>{section.label}</p>
      <ul className={styles.sidebarMenu}>
        {section.items
          .filter(item => item.roles.includes(role))
          .map(item => (
            <li key={item.href}>
              <SidebarLink href={item.href} icon={iconMap[item.icon] || '📄'} label={item.label} />
            </li>
          ))}
      </ul>
    </div>
  )
}

export function DashboardShell ({ role, children }: DashboardShellProps) {
  const router = useRouter()
  const { user, isLoading, loadUser, logout } = useAuthStore()

  useEffect(() => {
    loadUser()
  }, [loadUser])

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login')
      return
    }

    if (user && user.role !== role) {
      router.push(resolveRoleDestination(user.role))
    }
  }, [isLoading, user, role, router])

  async function handleSignOut () {
    await logout()
    router.push('/login')
  }

  if (isLoading) {
    return (
      <div className={styles.loading}>
        Loading...
      </div>
    )
  }

  if (!user || user.role !== role) {
    return null
  }

  const sections = sidebarConfig.sections.filter(section =>
    section.items.some(item => item.roles.includes(role))
  )

  // Map backend role to frontend role
  const displayRole = user.role === 'sales_rep' ? 'sales' : user.role

  return (
    <div className={styles.layout}>
      <aside className={styles.sidebar}>
        <div className={styles.sidebarHeader}>
          <Link href={resolveRoleDestination(displayRole)} className={styles.brand}>
            SCP Supplier
          </Link>
          <SidebarToggle />
        </div>
        <nav className={styles.sidebarNav}>
          {sections.map(section => renderSection(section, displayRole))}
        </nav>
        <div className={styles.sidebarFooter}>
          <UserAvatar user={user} />
          <button type='button' onClick={handleSignOut} className={styles.signOutButton}>
            Sign out
          </button>
        </div>
      </aside>
      <main className={styles.main}>
        <Suspense fallback={<div className={styles.loading}>Loading...</div>}>
          {children}
        </Suspense>
      </main>
    </div>
  )
}

