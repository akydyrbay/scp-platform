import type { HTMLAttributes, ReactNode } from 'react'
import clsx from 'clsx'

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
}

export function Card ({ className, children, ...props }: CardProps) {
  return (
    <div className={clsx('rounded-2xl border border-neutral-200 bg-white shadow-card', className)} {...props}>
      {children}
    </div>
  )
}

export function CardHeader ({ className, children, ...props }: CardProps) {
  return (
    <div className={clsx('space-y-1.5', className)} {...props}>
      {children}
    </div>
  )
}

export function CardTitle ({ className, children, ...props }: CardProps) {
  return (
    <h3 className={clsx('text-lg font-semibold tracking-tight', className)} {...props}>
      {children}
    </h3>
  )
}

export function CardDescription ({ className, children, ...props }: CardProps) {
  return (
    <p className={clsx('text-sm text-neutral-500', className)} {...props}>
      {children}
    </p>
  )
}

export function CardContent ({ className, children, ...props }: CardProps) {
  return (
    <div className={clsx('space-y-4', className)} {...props}>
      {children}
    </div>
  )
}

