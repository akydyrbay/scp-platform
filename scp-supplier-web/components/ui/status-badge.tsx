import clsx from 'clsx'

type StatusVariant = 'approved' | 'pending' | 'not-started' | 'cancelled' | 'completed' | 'returned'

const variantStyles: Record<StatusVariant, string> = {
  approved: 'bg-emerald-50 text-emerald-600 border border-emerald-100',
  pending: 'bg-amber-50 text-amber-600 border border-amber-100',
  'not-started': 'bg-rose-50 text-rose-600 border border-rose-100',
  cancelled: 'bg-rose-50 text-rose-600 border border-rose-100',
  completed: 'bg-sky-50 text-sky-600 border border-sky-100',
  returned: 'bg-slate-100 text-slate-600 border border-slate-200'
}

interface StatusBadgeProps {
  label: string
  variant: StatusVariant
}

export function StatusBadge ({ label, variant }: StatusBadgeProps) {
  return (
    <span className={clsx('inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold capitalize', variantStyles[variant])}>
      {label}
    </span>
  )
}


