type Trend = 'up' | 'down' | 'neutral'

interface KpiCardProps {
  title: string
  value: string
  delta?: {
    label: string
    value: string
    trend: Trend
  }
}

const trendColor: Record<Trend, string> = {
  up: 'text-emerald-300',
  down: 'text-rose-300',
  neutral: 'text-slate-300'
}

export function KpiCard ({ title, value, delta }: KpiCardProps) {
  return (
    <article className='rounded-2xl border border-slate-200/60 bg-white p-6 shadow-[0px_24px_60px_rgba(15,23,42,0.08)]'>
      <p className='text-xs uppercase tracking-[0.35em] text-slate-400'>{title}</p>
      <p className='mt-4 text-3xl font-semibold text-slate-900'>{value}</p>
      {delta ? (
        <p className={`mt-4 text-sm font-medium ${trendColor[delta.trend]}`}>
          {delta.value} · {delta.label}
        </p>
      ) : null}
    </article>
  )
}

