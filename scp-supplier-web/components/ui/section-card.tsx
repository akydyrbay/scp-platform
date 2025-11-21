import type { ReactNode } from 'react'

interface SectionCardProps {
  title: string
  description?: string
  action?: ReactNode
  children?: ReactNode
}

export function SectionCard ({ title, description, action, children }: SectionCardProps) {
  return (
    <section className='rounded-2xl border border-slate-200/60 bg-white p-6 shadow-[0px_16px_40px_rgba(15,23,42,0.06)]'>
      <header className='flex flex-wrap items-start justify-between gap-4'>
        <div>
          <h2 className='text-xl font-semibold text-slate-900'>{title}</h2>
          {description ? <p className='mt-1 text-sm text-slate-500'>{description}</p> : null}
        </div>
        {action ? <div className='flex-none'>{action}</div> : null}
      </header>
      {children ? (
        <div className='mt-4 space-y-4 text-slate-700'>
          {children}
        </div>
      ) : null}
    </section>
  )
}

