import { Suspense } from 'react'
import Link from 'next/link'
import { redirect } from 'next/navigation'

import type { Session, UserRole } from '@/types/auth'
import { clearSession, resolveRoleDestination } from '@/lib/auth'
import { sidebarConfig, type SidebarSection } from '@/constants/navigation'
import { UserAvatar } from '@/components/navigation/user-avatar'
import { SidebarToggle } from '@/components/navigation/sidebar-toggle'
import { SidebarLink } from '@/components/navigation/sidebar-link'
import styles from './dashboard-shell.module.styl'

interface DashboardShellProps {
  session: Session | null
  role: UserRole
  children: React.ReactNode
}

function renderSection (section: SidebarSection, role: UserRole) {
  return (
    <div key={section.label} className={styles.sidebarSection}>
      <p className={styles.sidebarSectionLabel}>{section.label}</p>
      <ul className={styles.sidebarMenu}>
        {section.items
          .filter(item => item.roles.includes(role))
          .map(item => (
            <li key={item.href}>
              <SidebarLink href={item.href} icon={item.icon} label={item.label} />
            </li>
          ))}
      </ul>
    </div>
  )
}

export function DashboardShell ({ session, role, children }: DashboardShellProps) {
  if (!session || session.user.role !== role) redirect(resolveRoleDestination(session?.user.role ?? 'owner'))

  const sections = sidebarConfig.sections.filter(section =>
    section.items.some(item => item.roles.includes(role))
  )

  async function signOut () {
    'use server'

    await clearSession()
    redirect('/login')
  }

  return (
    <div className={styles.layout}>
      <aside className={styles.sidebar}>
        <div className={styles.sidebarHeader}>
          <Link href={resolveRoleDestination(role)} className={styles.brand}>
            B2B Supplier
          </Link>
          <SidebarToggle />
        </div>
        <nav className={styles.sidebarNav}>
          {sections.map(section => renderSection(section, role))}
        </nav>
        <div className={styles.sidebarFooter}>
          <UserAvatar user={session.user} />
          <form action={signOut}>
            <button type='submit' className={styles.signOutButton}>
              Sign out
            </button>
          </form>
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

