'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import clsx from 'clsx'
import {
  Building2,
  Users2,
  Settings,
  PackageSearch,
  Boxes,
  ClipboardList,
  MessageSquareWarning
} from 'lucide-react'

const iconMap = {
  dashboard: Building2,
  team: Users2,
  settings: Settings,
  package: PackageSearch,
  catalog: Boxes,
  orders: ClipboardList,
  complaints: MessageSquareWarning
}

export type SidebarIconKey = keyof typeof iconMap

export interface SidebarItem {
  href: string
  label: string
  icon: SidebarIconKey
}

interface RoleSidebarNavProps {
  items: SidebarItem[]
}

export function RoleSidebarNav ({ items }: RoleSidebarNavProps) {
  const pathname = usePathname()

  return (
    <nav className='flex flex-col gap-4'>
      {items.map(item => {
        const Icon = iconMap[item.icon]
        const isActive = pathname.startsWith(item.href)

        return (
          <Link
            key={item.href}
            href={item.href}
            className={clsx(
              'flex items-center gap-3 rounded-2xl border px-4 py-3 text-sm font-semibold transition',
              isActive
                ? 'border-neutral-300 bg-neutral-200 text-neutral-900'
                : 'border-transparent bg-white text-neutral-600 hover:border-primary-100 hover:text-primary-500'
            )}
          >
            <span
              className={clsx(
                'inline-flex h-8 w-8 items-center justify-center rounded-xl',
                isActive ? 'bg-neutral-300 text-neutral-800' : 'bg-neutral-100 text-neutral-500'
              )}
            >
              <Icon className='h-4 w-4' />
            </span>
            {item.label}
          </Link>
        )
      })}
    </nav>
  )
}

