import type { InputHTMLAttributes } from 'react'
import clsx from 'clsx'

export function Input ({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
    return (
      <input
      className={clsx(
        'h-10 w-full rounded-xl border border-neutral-200 bg-white px-3 text-sm text-neutral-700 shadow-sm transition focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-100 disabled:cursor-not-allowed disabled:bg-neutral-100 disabled:text-neutral-400',
          className
        )}
        {...props}
      />
    )
  }
