import { type LucideIcon, Package, CheckCircle2, Clock, XCircle, Loader2, RotateCcw } from 'lucide-react'
import { Card } from '@/components/ui/card'

interface StatsCard {
  id: string
  label: string
  value: string
  trend?: string
  icon?: LucideIcon
  accent?: string
}

const defaultIcon = Package

const accentStyles: Record<string, string> = {
  blue: 'bg-primary-50 text-primary-600',
  green: 'bg-emerald-50 text-emerald-600',
  amber: 'bg-amber-50 text-amber-600',
  rose: 'bg-rose-50 text-rose-600',
  slate: 'bg-slate-100 text-slate-600'
}

const cardIcons: Record<string, LucideIcon> = {
  'total-orders': Package,
  'pending-orders': Clock,
  'approved-orders': CheckCircle2,
  'completed-orders': CheckCircle2,
  'cancelled-orders': XCircle,
  'returned-orders': RotateCcw,
  default: defaultIcon
}

const cardAccent: Record<string, string> = {
  'total-orders': 'blue',
  'pending-orders': 'amber',
  'approved-orders': 'green',
  'completed-orders': 'green',
  'cancelled-orders': 'rose',
  'returned-orders': 'slate',
  default: 'blue'
}

interface StatsCardsProps {
  cards: StatsCard[]
}

export function StatsCards ({ cards }: StatsCardsProps) {
  return (
    <div className='grid gap-6 lg:grid-cols-3 2xl:grid-cols-6'>
      {cards.map(card => {
        const Icon = card.icon ?? cardIcons[card.id] ?? cardIcons.default
        const accent = accentStyles[card.accent ?? cardAccent[card.id] ?? cardAccent.default]

        return (
          <Card key={card.id} className='p-6'>
            <div className='flex items-center justify-between'>
              <div className='flex flex-col gap-2'>
                <p className='text-sm font-medium text-neutral-500'>{card.label}</p>
                <div className='flex items-end gap-2'>
                  <p className='text-3xl font-semibold text-neutral-900'>{card.value}</p>
                  {card.trend ? (
                    <span className='text-xs font-semibold text-success'>{card.trend}</span>
                  ) : null}
                </div>
              </div>
              <span className={`inline-flex h-12 w-12 items-center justify-center rounded-2xl ${accent}`}>
                <Icon className='h-6 w-6' />
              </span>
            </div>
          </Card>
        )
      })}
    </div>
  )
}


