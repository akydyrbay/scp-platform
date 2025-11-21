import type { LabelHTMLAttributes } from 'react'
import clsx from 'clsx'

export function Label ({ className, ...props }: LabelHTMLAttributes<HTMLLabelElement>) {
  return (
    <label
      className={clsx('text-sm font-medium text-neutral-600', className)}
      {...props}
    />
  )
}

