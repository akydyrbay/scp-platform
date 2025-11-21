 'use client'

import { useCallback, useEffect, useState } from 'react'

import styles from './sidebar-toggle.module.styl'

export function SidebarToggle () {
  const [isCollapsed, setIsCollapsed] = useState(false)

  useEffect(() => {
    document.documentElement.setAttribute('data-sidebar', isCollapsed ? 'collapsed' : 'expanded')
  }, [isCollapsed])

  const handleToggle = useCallback(() => {
    setIsCollapsed(state => !state)
  }, [])

  return (
    <button
      type='button'
      className={styles.toggle}
      aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
      onClick={handleToggle}
    >
      <span className={styles.bar} />
      <span className={styles.bar} />
      <span className={styles.bar} />
    </button>
  )
}

