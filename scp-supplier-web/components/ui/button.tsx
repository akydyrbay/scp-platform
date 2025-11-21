import type { ButtonHTMLAttributes } from 'react'
import clsx from 'clsx'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary'
}

export function Button ({ className, variant = 'primary', ...props }: ButtonProps) {
  const variants = {
    primary: 'bg-primary-500 hover:bg-primary-600 text-white shadow-[0_12px_24px_rgba(59,130,246,0.35)]',
    secondary: 'border border-neutral-200 bg-white hover:border-primary-200 text-neutral-600 hover:text-primary-500'
  }

  return (
    <button
      className={clsx(
        'inline-flex h-10 w-full items-center justify-center rounded-xl px-4 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-primary-200 disabled:cursor-not-allowed disabled:opacity-60',
        variants[variant],
        className
      )}
      {...props}
    />
  )
}

