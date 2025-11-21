'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useMemo } from 'react'

import styles from './sidebar-link.module.styl'

interface SidebarLinkProps {
  href: string
  icon: string
  label: string
}

export function SidebarLink ({ href, icon, label }: SidebarLinkProps) {
  const pathname = usePathname()

  const isActive = useMemo(() => {
    if (!pathname) return false
    return pathname === href || pathname.startsWith(`${href}/`)
  }, [href, pathname])

  return (
    <Link href={href} className={`${styles.link} ${isActive ? styles.active : ''}`}>
      <span className={styles.icon}>{icon}</span>
      <span>{label}</span>
    </Link>
  )
}


