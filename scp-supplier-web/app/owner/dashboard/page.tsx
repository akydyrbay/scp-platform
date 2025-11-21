'use client'

import { useEffect, useState } from 'react'
import { getDashboardStats } from '@/lib/api/dashboard'
import type { DashboardStats } from '@/lib/api/dashboard'
import toast from 'react-hot-toast'

const chartData = [
  { month: 'Jan', value: 420 },
  { month: 'Feb', value: 480 },
  { month: 'Mar', value: 530 },
  { month: 'Apr', value: 610 },
  { month: 'May', value: 720 },
  { month: 'Jun', value: 690 },
  { month: 'Jul', value: 750 },
  { month: 'Aug', value: 830 },
  { month: 'Sep', value: 910 },
  { month: 'Oct', value: 980 },
  { month: 'Nov', value: 1050 },
  { month: 'Dec', value: 1120 }
]

const maxValue = Math.max(...chartData.map(point => point.value))
const step = 5
const yTicks = Array.from({ length: step + 1 }, (_, index) => Math.round((maxValue / step) * index))

export default function OwnerDashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setIsLoading(true)
        const data = await getDashboardStats()
        setStats(data)
        console.log('Dashboard stats loaded:', data)
      } catch (error) {
        console.error('Failed to fetch dashboard stats:', error)
        toast.error('Failed to load dashboard data')
      } finally {
        setIsLoading(false)
      }
    }

    fetchStats()
  }, [])
  return (
    <div className='flex w-full justify-center'>
      <section className='flex w-[1099px] max-w-full flex-col rounded-[32px] border border-[#E3E8EF] bg-white px-12 py-12 shadow-[0_40px_80px_rgba(15,23,42,0.05)]'>
        <header className='mb-10 flex flex-wrap items-start justify-between gap-6'>
          <div>
            <p className='text-xs uppercase tracking-[0.4em] text-neutral-400'>Owner Dashboard</p>
            <h2 className='mt-3 text-3xl font-semibold text-neutral-900'>Revenue Performance</h2>

          </div>
          <button className='rounded-xl border border-neutral-200 px-5 py-3 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'>
            Download Report
          </button>
        </header>

        <div className='flex flex-col gap-8 xl:flex-row xl:gap-[86px]'>
          <div className='w-full flex-1 rounded-[28px] border border-[#E3E8EF] bg-[#F9FBFF] p-8'>
            <div className='flex items-center justify-between'>
              <h3 className='text-lg font-semibold text-neutral-900'>Monthly Revenue</h3>
              <p className='text-sm text-neutral-500'>FY 2025 · USD</p>
            </div>
            <div className='mt-6 h-[500px] w-full'>
              <svg viewBox='0 0 800 500' className='h-full w-full'>
                {/* Y-axis grid and labels */}
                {yTicks.map((tick, index) => {
                  const y = 460 - (tick / maxValue) * 380
                  return (
                    <g key={tick}>
                      <line x1='60' y1={y} x2='770' y2={y} stroke='#E3E8EF' strokeWidth='1' strokeDasharray='4 6' />
                      <text x='40' y={y + 5} fill='#94A3B8' fontSize='12' textAnchor='end'>
                        ₸ {tick.toLocaleString()}
                      </text>
                    </g>
                  )
                })}

                {/* Axis lines */}
                <line x1='60' y1='460' x2='770' y2='460' stroke='#CBD5E1' strokeWidth='1.5' />
                <line x1='60' y1='80' x2='60' y2='460' stroke='#CBD5E1' strokeWidth='1.5' />

                {/* Line path */}
                <path
                  d={chartData
                    .map((point, index) => {
                      const x = 60 + (index / (chartData.length - 1)) * 710
                      const y = 460 - (point.value / maxValue) * 380
                      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`
                    })
                    .join(' ')}
                  fill='none'
                  stroke='#2563EB'
                  strokeWidth='3'
                  strokeLinecap='round'
                />

                {/* Area gradient */}
                <defs>
                  <linearGradient id='lineGradient' x1='0' x2='0' y1='0' y2='1'>
                    <stop offset='0%' stopColor='#2563EB' stopOpacity='0.25' />
                    <stop offset='100%' stopColor='#2563EB' stopOpacity='0' />
                  </linearGradient>
                </defs>

                <path
                  d={`M 60 460 ${chartData
                    .map((point, index) => {
                      const x = 60 + (index / (chartData.length - 1)) * 710
                      const y = 460 - (point.value / maxValue) * 380
                      return `L ${x} ${y}`
                    })
                    .join(' ')} L 770 460 Z`}
                  fill='url(#lineGradient)'
                  opacity='0.8'
                />

                {/* Points and labels */}
                {chartData.map((point, index) => {
                  const x = 60 + (index / (chartData.length - 1)) * 710
                  const y = 460 - (point.value / maxValue) * 380
                  return (
                    <g key={point.month}>
                      <circle cx={x} cy={y} r='6' fill='#2563EB' stroke='white' strokeWidth='2' />
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
            <div className='rounded-[24px] border border-[#E3E8EF] bg-white p-6 shadow-[0_20px_40px_rgba(15,23,42,0.06)]'>
              <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Total Orders</p>
              <p className='mt-4 text-3xl font-semibold text-neutral-900'>
                {isLoading ? '...' : (stats?.total_orders || 0)}
              </p>
              <p className='mt-2 text-sm text-neutral-500'>Total orders received from consumers.</p>
            </div>

            <div className='rounded-[24px] border border-[#E3E8EF] bg-white p-6 shadow-[0_20px_40px_rgba(15,23,42,0.06)]'>
              <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Pending Orders</p>
              <p className='mt-4 text-3xl font-semibold text-neutral-900'>
                {isLoading ? '...' : (stats?.pending_orders || 0)}
              </p>
              <p className='mt-2 text-sm text-neutral-500'>Orders awaiting your approval or rejection.</p>
            </div>

            <div className='rounded-[24px] border border-[#E3E8EF] bg-white p-6 shadow-[0_20px_40px_rgba(15,23,42,0.06)]'>
              <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Low Stock</p>
              <p className='mt-4 text-3xl font-semibold text-neutral-900'>
                {isLoading ? '...' : (stats?.low_stock_items || 0)}
              </p>
              <p className='mt-2 text-sm text-neutral-500'>Products with low inventory levels.</p>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

