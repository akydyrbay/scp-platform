import styles from './user-avatar.module.styl'
import type { User } from '@/lib/types'

interface UserAvatarProps {
  user: User
}

export function UserAvatar ({ user }: UserAvatarProps) {
  const firstName = user.firstName || user.first_name
  const lastName = user.lastName || user.last_name
  
  const name = firstName && lastName 
    ? `${firstName} ${lastName}` 
    : user.email.split('@')[0]
  
  const initials = name
    .split(' ')
    .map(token => token[0])
    .join('')
    .slice(0, 2)
    .toUpperCase()

  const displayName = firstName && lastName
    ? `${firstName} ${lastName}`
    : user.email

  return (
    <div className={styles.avatarCard}>
      <div className={styles.avatar}>{initials}</div>
      <div>
        <p className={styles.name}>{displayName}</p>
        <p className={styles.meta}>{user.role}</p>
        <p className={styles.meta}>{user.email}</p>
      </div>
    </div>
  )
}

