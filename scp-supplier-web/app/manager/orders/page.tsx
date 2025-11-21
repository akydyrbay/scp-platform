'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import toast from 'react-hot-toast'

import { PageHeader } from '@/components/ui/page-header'
import { getOrders, acceptOrder, rejectOrder, type Order } from '@/lib/api/orders'

const orderFilters = ['All', 'Pending', 'Accepted', 'Completed', 'Rejected', 'Cancelled'] as const

type OrderStatus = (typeof orderFilters)[number]

type DeliveryWindow = {
  date: string
  start: string
  end: string
}

type OrderRecord = {
  id: string
  retailer: string
  submittedAt: string
  items: string[]
  amount: string
  status: OrderStatus
  notes?: string
  delivery?: DeliveryWindow
}

// Map backend order to UI order
function mapOrderToUI(order: Order): OrderRecord {
  const submittedAt = new Date(order.created_at).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })

  const items = order.items?.map(item => 
    `${item.quantity} ${item.product?.unit || 'units'} ${item.product?.name || 'Product'}`
  ) || []

  const amount = `₸ ${order.total.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`

  const statusMap: Record<string, OrderStatus> = {
    pending: 'Pending',
    accepted: 'Accepted',
    completed: 'Completed',
    rejected: 'Rejected',
    cancelled: 'Cancelled'
  }

  const delivery = order.delivery_date && order.delivery_start_time && order.delivery_end_time
    ? {
        date: new Date(order.delivery_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        start: order.delivery_start_time,
        end: order.delivery_end_time
      }
    : undefined

  return {
    id: order.id,
    retailer: order.consumer_id || 'Retailer',
    submittedAt,
    items,
    amount,
    status: statusMap[order.status.toLowerCase()] || 'Pending',
    notes: order.notes || undefined,
    delivery
  }
}

const statusFillStyles: Record<OrderStatus, string> = {
  All: 'bg-neutral-300',
  Pending: 'bg-sky-500',
  Accepted: 'bg-amber-400',
  Completed: 'bg-emerald-500',
  Rejected: 'bg-rose-500',
  Cancelled: 'bg-neutral-400'
}

const statusOutlineStyles: Record<OrderStatus, string> = {
  All: 'border-neutral-300 text-neutral-500',
  Pending: 'border-sky-500 text-sky-600',
  Accepted: 'border-amber-400 text-amber-500',
  Completed: 'border-emerald-500 text-emerald-600',
  Rejected: 'border-rose-500 text-rose-500',
  Cancelled: 'border-neutral-400 text-neutral-500'
}

function formatDelivery (delivery?: DeliveryWindow) {
  if (!delivery) return null
  return `${delivery.date} · ${delivery.start} - ${delivery.end}`
}

export default function ManagerOrdersPage () {
  const [activeFilter, setActiveFilter] = useState<(typeof orderFilters)[number]>('All')
  const [orders, setOrders] = useState<Order[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        setIsLoading(true)
        const data = await getOrders(1, 100)
        setOrders(data.results || [])
      } catch (error) {
        console.error('Failed to fetch orders:', error)
        // getOrders now returns empty array instead of throwing, so this is unlikely
        setOrders([])
        toast.error('Failed to load orders')
      } finally {
        setIsLoading(false)
      }
    }

    fetchOrders()
  }, [])

  const uiOrders = useMemo(() => orders.map(mapOrderToUI), [orders])

  const pendingOrders = useMemo(
    () => uiOrders.filter(order => order.status === 'Pending' && (activeFilter === 'All' || activeFilter === 'Pending')),
    [uiOrders, activeFilter]
  )

  const processedOrders = useMemo(() => {
    if (activeFilter === 'All') return uiOrders.filter(order => order.status !== 'Pending')
    if (activeFilter === 'Pending') return []
    return uiOrders.filter(order => order.status === activeFilter)
  }, [uiOrders, activeFilter])

  const handleAccept = async (id: string) => {
    try {
      await acceptOrder(id)
      toast.success('Order accepted successfully')
      // Refresh orders
      const data = await getOrders(1, 100)
      setOrders(data.results)
    } catch (error) {
      console.error('Failed to accept order:', error)
      toast.error('Failed to accept order')
    }
  }

  const handleReject = async (id: string) => {
    if (!confirm('Are you sure you want to reject this order?')) return
    
    try {
      await rejectOrder(id)
      toast.success('Order rejected successfully')
      // Refresh orders
      const data = await getOrders(1, 100)
      setOrders(data.results)
    } catch (error) {
      console.error('Failed to reject order:', error)
      toast.error('Failed to reject order')
    }
  }

  if (isLoading) {
    return (
      <div className='space-y-10'>
        <PageHeader
          title='Order Management'
          description='Manage fresh market wholesale orders, confirm allocations, and maintain service levels.'
        />
        <div className='text-center text-neutral-500'>Loading orders...</div>
      </div>
    )
  }

  return (
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
                  <span className={`rounded-full px-3 py-1 text-xs font-semibold text-white ${statusFillStyles[order.status]}`}>{order.id}</span>
                  <p className='text-lg font-semibold text-neutral-900'>{order.retailer}</p>
                  <span className='text-xs text-neutral-500'>{order.submittedAt}</span>
                </div>
                <div className='space-y-1 text-sm text-neutral-600'>
                  {order.items.map(item => (
                    <p key={item}>{item}</p>
                  ))}
                </div>
                {order.delivery ? (
                  <p className='flex items-center gap-2 text-sm text-neutral-500'>
                    <span className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Delivery</span>
                    {formatDelivery(order.delivery)}
                  </p>
                ) : null}
                <p className='text-base font-semibold text-neutral-900'>{order.amount}</p>
                {order.notes ? <p className='text-sm text-neutral-500'>{order.notes}</p> : null}
              </div>
              <div className='flex flex-col gap-3'>
                {order.status === 'Pending' ? (
                  <>
                    <Link href={`/manager/orders/${order.id}`} className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-neutral-300 hover:text-neutral-700'>
                      View Details
                    </Link>
                    <button 
                      onClick={() => handleAccept(order.id)}
                      className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'>
                      Accept Order
                    </button>
                    <button 
                      onClick={() => handleReject(order.id)}
                      className='rounded-xl border border-rose-300 px-4 py-2 text-sm font-semibold text-rose-500 transition hover:border-rose-400 hover:text-rose-600'>
                      Reject Order
                    </button>
                  </>
                ) : (
                  <>
                    <span className={`inline-flex items-center justify-center rounded-xl border px-4 py-2 text-xs font-semibold ${statusOutlineStyles[order.status]}`}>
                      {order.status}
                    </span>
                    <Link href={`/manager/orders/${order.id}`} className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-neutral-300 hover:text-neutral-700'>
                      View Details
                    </Link>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

