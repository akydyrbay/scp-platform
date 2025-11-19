import type { ReactNode } from 'react'

interface PageHeaderProps {
  title: string
  description: string
  cta?: ReactNode
}

export function PageHeader ({ title, description, cta }: PageHeaderProps) {
  return (
    <header className='mb-10 flex flex-wrap items-center justify-between gap-6'>
      <div>
        <h1 className='text-3xl font-semibold text-neutral-900'>{title}</h1>
        <p className='mt-2 text-neutral-500 max-w-2xl'>{description}</p>
      </div>
      {cta ? <div className='flex-none'>{cta}</div> : null}
    </header>
  )
}

