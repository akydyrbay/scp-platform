import styles from './user-avatar.module.styl'

interface UserAvatarProps {
  user: {
    name: string
    email: string
    role: string
  }
}

export function UserAvatar ({ user }: UserAvatarProps) {
  const initials = user.name
    .split(' ')
    .map(token => token[0])
    .join('')
    .slice(0, 2)
    .toUpperCase()

  return (
    <div className={styles.avatarCard}>
      <div className={styles.avatar}>{initials}</div>
      <div>
        <p className={styles.name}>{user.name}</p>
        <p className={styles.meta}>{user.role}</p>
        <p className={styles.meta}>{user.email}</p>
      </div>
    </div>
  )
}


