'use client'

import { useEffect, useState } from 'react'
import { getDashboardStats } from '@/lib/api/dashboard'
import type { DashboardStats } from '@/lib/api/dashboard'
import toast from 'react-hot-toast'

const approvalTrend = [
  { month: 'Jan', value: 62 },
  { month: 'Feb', value: 68 },
  { month: 'Mar', value: 71 },
  { month: 'Apr', value: 76 },
  { month: 'May', value: 83 },
  { month: 'Jun', value: 87 },
  { month: 'Jul', value: 92 },
  { month: 'Aug', value: 95 },
  { month: 'Sep', value: 97 },
  { month: 'Oct', value: 94 },
  { month: 'Nov', value: 98 },
  { month: 'Dec', value: 99 }
]

const maxValue = 100
const yTicks = [50, 60, 70, 80, 90, 100]

export default function ManagerDashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setIsLoading(true)
        const data = await getDashboardStats()
        setStats(data)
      } catch (error) {
        console.error('Failed to fetch dashboard stats:', error)
        toast.error('Failed to load dashboard data')
      } finally {
        setIsLoading(false)
      }
    }

    fetchStats()
  }, [])

  // Format orders for display
  const backlogOrders = stats?.recent_orders?.slice(0, 4).map((order: any) => ({
    id: order.id || `PO-${order.id?.slice(0, 5)}`,
    retailer: order.consumer_id || 'Retailer',
    due: order.delivery_date ? new Date(order.delivery_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'N/A'
  })) || []

  // Calculate service alerts from stats
  const serviceAlerts = stats ? [
    { label: 'Total Orders', value: stats.total_orders.toString(), context: 'All time' },
    { label: 'Pending Orders', value: stats.pending_orders.toString(), context: 'Requiring action' },
    { label: 'Low Stock Items', value: stats.low_stock_items.toString(), context: 'Needs attention' }
  ] : [
    { label: 'Total Orders', value: '0', context: 'Loading...' },
    { label: 'Pending Orders', value: '0', context: 'Loading...' },
    { label: 'Low Stock Items', value: '0', context: 'Loading...' }
  ]

  if (isLoading) {
    return (
      <div className='flex w-full justify-center'>
        <section className='flex w-[1099px] max-w-full flex-col rounded-[32px] border border-[#E3E8EF] bg-white px-12 py-12 shadow-[0_40px_80px_rgba(15,23,42,0.05)]'>
          <div className='text-center text-neutral-500'>Loading dashboard data...</div>
        </section>
      </div>
    )
  }
  return (
    <div className='flex w-full justify-center'>
      <section className='flex w-[1099px] max-w-full flex-col rounded-[32px] border border-[#E3E8EF] bg-white px-12 py-12 shadow-[0_40px_80px_rgba(15,23,42,0.05)]'>
        <header className='mb-10 flex flex-wrap items-start justify-between gap-6'>
          <div>
            <p className='text-xs uppercase tracking-[0.4em] text-neutral-400'>Manager Dashboard</p>
            <h2 className='mt-3 text-3xl font-semibold text-neutral-900'>Approval Performance</h2>
          </div>
        </header>

        <div className='flex flex-col gap-8 xl:flex-row xl:gap-[86px]'>
          <div className='w-full flex-1 rounded-[28px] border border-[#E3E8EF] bg-[#F9FBFF] p-8'>
            <div className='flex items-center justify-between'>
              <h3 className='text-lg font-semibold text-neutral-900'>Order Approval Rate</h3>
              <p className='text-sm text-neutral-500'>FY 2025 · percentage</p>
            </div>
            <div className='mt-6 h-[500px] w-full'>
              <svg viewBox='0 0 800 500' className='h-full w-full'>
                {yTicks.map(tick => {
                  const y = 460 - (tick / maxValue) * 380
                  return (
                    <g key={tick}>
                      <line x1='60' y1={y} x2='770' y2={y} stroke='#E3E8EF' strokeWidth='1' strokeDasharray='4 6' />
                      <text x='40' y={y + 5} fill='#94A3B8' fontSize='12' textAnchor='end'>
                        {tick}%
                      </text>
                    </g>
                  )
                })}

                <line x1='60' y1='460' x2='770' y2='460' stroke='#CBD5E1' strokeWidth='1.5' />
                <line x1='60' y1='80' x2='60' y2='460' stroke='#CBD5E1' strokeWidth='1.5' />

                <defs>
                  <linearGradient id='managerGradient' x1='0' x2='0' y1='0' y2='1'>
                    <stop offset='0%' stopColor='#22c55e' stopOpacity='0.3' />
                    <stop offset='100%' stopColor='#22c55e' stopOpacity='0' />
                  </linearGradient>
                </defs>

                <path
                  d={`M 60 460 ${approvalTrend
                    .map((point, index) => {
                      const x = 60 + (index / (approvalTrend.length - 1)) * 710
                      const y = 460 - (point.value / maxValue) * 380
                      return `L ${x} ${y}`
                    })
                    .join(' ')} L 770 460 Z`}
                  fill='url(#managerGradient)'
                  opacity='0.8'
                />

                <path
                  d={approvalTrend
                    .map((point, index) => {
                      const x = 60 + (index / (approvalTrend.length - 1)) * 710
                      const y = 460 - (point.value / maxValue) * 380
                      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`
                    })
                    .join(' ')}
                  fill='none'
                  stroke='#22c55e'
                  strokeWidth='3'
                  strokeLinecap='round'
                />

                {approvalTrend.map((point, index) => {
                  const x = 60 + (index / (approvalTrend.length - 1)) * 710
                  const y = 460 - (point.value / maxValue) * 380
                  return (
                    <g key={point.month}>
                      <circle cx={x} cy={y} r='6' fill='#22c55e' stroke='white' strokeWidth='2' />
                      <text x={x} y='490' fill='#64748B' fontSize='12' textAnchor='middle'>
                        {point.month}
                      </text>
                    </g>
                  )
                })}
              </svg>
            </div>
          </div>

          <div className='flex w-full max-w-[203px] flex-col gap-6'>
            {serviceAlerts.map(item => (
              <div key={item.label} className='rounded-[24px] border border-[#E3E8EF] bg-white p-6 shadow-[0_20px_40px_rgba(15,23,42,0.06)]'>
                <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>{item.label}</p>
                <p className='mt-4 text-3xl font-semibold text-neutral-900'>{item.value}</p>
                <p className='mt-2 text-sm text-neutral-500'>{item.context}</p>
              </div>
            ))}
          </div>
        </div>

        <div className='mt-10 rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
          <header className='mb-6 flex flex-wrap items-center justify-between gap-4'>
            <div>
              <h3 className='text-xl font-semibold text-neutral-900'>Orders Requiring Action</h3>
            </div>
            <button className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'>
              View All Orders
            </button>
          </header>

          <div className='overflow-hidden rounded-2xl border border-neutral-100'>
            <table className='min-w-full divide-y divide-neutral-100 text-left'>
              <thead className='bg-neutral-50 text-xs uppercase tracking-[0.3em] text-neutral-500'>
                <tr>
                  <th className='px-6 py-4'>Order</th>
                  <th className='px-6 py-4'>Retailer</th>
                  <th className='px-6 py-4'>Due</th>
                </tr>
              </thead>
              <tbody className='divide-y divide-neutral-100 text-sm text-neutral-700'>
                {backlogOrders.map(order => (
                  <tr key={order.id} className='transition hover:bg-neutral-50'>
                    <td className='px-6 py-4 font-semibold text-neutral-900'>{order.id}</td>
                    <td className='px-6 py-4'>{order.retailer}</td>

                    <td className='px-6 py-4'>{order.due}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>
  )
}

