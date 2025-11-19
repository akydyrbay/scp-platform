'use client'

import { useQuery } from '@tanstack/react-query'
import { useMemo, useState } from 'react'
import Link from 'next/link'
import { getOrders, acceptOrder, rejectOrder } from '@/lib/api/orders'
import { DashboardShell } from '@/components/layout/dashboard-shell'
import { PageHeader } from '@/components/ui/page-header'
import toast from 'react-hot-toast'

const orderFilters = ['All', 'Pending', 'Accepted', 'Completed', 'Rejected', 'Cancelled'] as const

type OrderStatus = (typeof orderFilters)[number]

export default function ManagerOrdersPage () {
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
  const [activeFilter, setActiveFilter] = useState<OrderStatus>('All')

  const { data: orders = [], isLoading, refetch } = useQuery({
    queryKey: ['orders'],
    queryFn: () => getOrders(token || undefined),
    enabled: !!token,
  })

  const filteredOrders = useMemo(() => {
    if (activeFilter === 'All') return orders
    return orders.filter(order => order.status === activeFilter.toLowerCase())
  }, [activeFilter, orders])

  const pendingOrders = useMemo(
    () => filteredOrders.filter(order => order.status === 'pending'),
    [filteredOrders]
  )

  const processedOrders = useMemo(() => {
    if (activeFilter === 'Pending') return []
    return filteredOrders.filter(order => order.status !== 'pending')
  }, [activeFilter, filteredOrders])

  const statusFillStyles: Record<string, string> = {
    All: 'bg-neutral-300',
    Pending: 'bg-sky-500',
    Accepted: 'bg-amber-400',
    Completed: 'bg-emerald-500',
    Rejected: 'bg-rose-500',
    Cancelled: 'bg-neutral-400'
  }

  const statusOutlineStyles: Record<string, string> = {
    All: 'border-neutral-300 text-neutral-500',
    Pending: 'border-sky-500 text-sky-600',
    Accepted: 'border-amber-400 text-amber-500',
    Completed: 'border-emerald-500 text-emerald-600',
    Rejected: 'border-rose-500 text-rose-500',
    Cancelled: 'border-neutral-400 text-neutral-500'
  }

  async function handleAccept(orderId: string) {
    try {
      await acceptOrder(orderId, token || undefined)
      toast.success('Order accepted')
      refetch()
    } catch (error: any) {
      toast.error(error.response?.data?.error?.message || 'Failed to accept order')
    }
  }

  async function handleReject(orderId: string) {
    try {
      await rejectOrder(orderId, token || undefined)
      toast.success('Order rejected')
      refetch()
    } catch (error: any) {
      toast.error(error.response?.data?.error?.message || 'Failed to reject order')
    }
  }

  if (isLoading) {
    return (
      <DashboardShell role="manager">
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
            <p className="mt-4 text-sm text-neutral-500">Loading orders...</p>
          </div>
        </div>
      </DashboardShell>
    )
  }

  return (
    <DashboardShell role="manager">
      <div className='space-y-10'>
        <PageHeader
          title='Order Management'
          description='Manage fresh market wholesale orders, confirm allocations, and maintain service levels.'
        />

        <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)] space-y-6'>
          <div className='flex flex-wrap items-center justify-between gap-4'>
            <div className='relative w-full max-w-xl'>
              <input
                type='search'
                placeholder='Search by Order ID'
                className='h-11 w-full rounded-xl border border-neutral-200 bg-neutral-50 px-4 pl-11 text-sm text-neutral-700 outline-none transition focus:border-primary-400 focus:bg-white focus:shadow-sm'
              />
              <span className='pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400'>🔍</span>
            </div>
            <div className='flex flex-wrap gap-3'>
              {orderFilters.map(filter => (
                <button
                  key={filter}
                  onClick={() => setActiveFilter(filter)}
                  className={`rounded-xl border px-4 py-2 text-sm font-semibold transition whitespace-nowrap ${
                    activeFilter === filter
                      ? 'border-primary-100 bg-primary-50 text-primary-600 shadow-[0_12px_24px_rgba(59,130,246,0.12)]'
                      : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-100 hover:text-primary-500'
                  }`}
                >
                  {filter}
                </button>
              ))}
            </div>
          </div>

          <div className='space-y-4'>
            {[...pendingOrders, ...processedOrders].map(order => (
              <div key={order.id} className='flex flex-wrap gap-6 rounded-2xl border border-neutral-100 bg-white p-6 shadow-sm shadow-neutral-200/40'>
                <div className='flex flex-1 flex-col gap-4'>
                  <div className='flex flex-wrap items-center gap-3'>
                    <span className={`rounded-full px-3 py-1 text-xs font-semibold text-white ${statusFillStyles[order.status.charAt(0).toUpperCase() + order.status.slice(1)] || statusFillStyles.All}`}>
                      #{order.id.slice(-8)}
                    </span>
                    <p className='text-lg font-semibold text-neutral-900'>{order.consumerName || 'Unknown Consumer'}</p>
                    <span className='text-xs text-neutral-500'>
                      {new Date(order.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                  <div className='space-y-1 text-sm text-neutral-600'>
                    {order.items.map(item => (
                      <p key={item.id}>{item.quantity} {item.productName || 'items'} @ ₸ {item.unitPrice.toLocaleString()}</p>
                    ))}
                  </div>
                  <p className='text-base font-semibold text-neutral-900'>Total: ₸ {order.total.toLocaleString()}</p>
                </div>
                <div className='flex flex-col gap-3'>
                  {order.status === 'pending' ? (
                    <>
                      <Link href={`/manager/orders/${order.id}`} className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-neutral-300 hover:text-neutral-700 text-center'>
                        View Details
                      </Link>
                      <button
                        onClick={() => handleAccept(order.id)}
                        className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'
                      >
                        Accept Order
                      </button>
                      <button
                        onClick={() => handleReject(order.id)}
                        className='rounded-xl border border-rose-300 px-4 py-2 text-sm font-semibold text-rose-500 transition hover:border-rose-400 hover:text-rose-600'
                      >
                        Reject Order
                      </button>
                    </>
                  ) : (
                    <>
                      <span className={`inline-flex items-center justify-center rounded-xl border px-4 py-2 text-xs font-semibold ${statusOutlineStyles[order.status.charAt(0).toUpperCase() + order.status.slice(1)] || statusOutlineStyles.All}`}>
                        {order.status}
                      </span>
                      <Link href={`/manager/orders/${order.id}`} className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-neutral-300 hover:text-neutral-700 text-center'>
                        View Details
                      </Link>
                    </>
                  )}
                </div>
              </div>
            ))}
            {filteredOrders.length === 0 && (
              <div className='rounded-2xl border border-dashed border-neutral-200 bg-neutral-50 p-10 text-center text-sm text-neutral-500'>
                No orders found
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardShell>
  )
}

