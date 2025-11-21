import { useMemo } from 'react'

interface LineChartProps {
  title: string
  data: number[]
  labels: string[]
  accent?: string
}

export function LineChart ({ title, data, labels, accent = '#4f46e5' }: LineChartProps) {
  const { path, fill, points } = useMemo(() => {
    if (data.length === 0) {
      return {
        path: '',
        fill: '',
        points: [] as Array<{ x: number, y: number, value: number, label: string }>
      }
    }

    const max = Math.max(...data)
    const min = Math.min(...data)
    const range = max - min || 1

    const coords = data.map((value, index) => {
      const x = (index / Math.max(1, data.length - 1)) * 100
      const y = 100 - ((value - min) / range) * 70 - 10
      return { x, y, value, label: labels[index] ?? '' }
    })

    const linePath = coords
      .map((point, index) => `${index === 0 ? 'M' : 'L'} ${point.x},${point.y}`)
      .join(' ')

    const areaPath = `${coords.length ? `M ${coords[0].x},100` : ''} ${coords
      .map(point => `L ${point.x},${point.y}`)
      .join(' ')} ${coords.length ? `L ${coords[coords.length - 1].x},100 Z` : ''}`

    return { path: linePath, fill: areaPath, points: coords }
  }, [data, labels])

  const gradientId = `chartGradient-${title.replace(/\s+/g, '-')}`

  return (
    <div className='rounded-2xl border border-slate-200/60 bg-white p-6 shadow-[0px_16px_40px_rgba(15,23,42,0.06)]'>
      <div className='flex items-center justify-between'>
        <div>
          <p className='text-sm font-medium text-slate-500 uppercase tracking-[0.3em]'>{title}</p>
          <p className='mt-2 text-3xl font-semibold text-slate-900'>{data[data.length - 1]?.toLocaleString() ?? '-'}</p>
        </div>
        <span className='rounded-full bg-[rgba(79,70,229,0.08)] px-3 py-1 text-sm text-slate-600'>
          {labels.at(-1) ?? ''}
        </span>
      </div>

      <div className='mt-6 h-64 w-full'>
        <svg viewBox='0 0 100 100' preserveAspectRatio='none' className='h-full w-full'>
          <defs>
            <linearGradient id={gradientId} x1='0' x2='0' y1='0' y2='1'>
              <stop offset='0%' stopColor={accent} stopOpacity='0.18' />
              <stop offset='85%' stopColor={accent} stopOpacity='0.02' />
            </linearGradient>
          </defs>
          <path d={fill} fill={`url(#${gradientId})`} stroke='none' />
          <path d={path} fill='none' stroke={accent} strokeWidth='1.8' strokeLinecap='round' />
          {points.map(point => (
            <g key={`${point.x}-${point.value}`}>
              <circle cx={point.x} cy={point.y} r='2' fill={accent} />
            </g>
          ))}
        </svg>
      </div>

      <div className='mt-4 flex flex-wrap gap-3 text-xs text-slate-500'>
        {labels.map((label, index) => (
          <span key={label} className='rounded-full bg-slate-100 px-3 py-1'>
            {label} · {data[index]?.toLocaleString() ?? '-'}
          </span>
        ))}
      </div>
    </div>
  )
}

