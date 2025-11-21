'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { useParams, useRouter } from 'next/navigation'
import { getOrder, type Order } from '@/lib/api/orders'
import toast from 'react-hot-toast'

export default function ManagerOrderDetailPage() {
  const params = useParams<{ orderId: string }>()
  const router = useRouter()
  const [order, setOrder] = useState<Order | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchOrder = async () => {
      if (!params.orderId) return
      try {
        setIsLoading(true)
        const data = await getOrder(params.orderId)
        setOrder(data)
      } catch (error) {
        console.error('Failed to fetch order details:', error)
        toast.error('Failed to load order details')
        setOrder(null)
      } finally {
        setIsLoading(false)
      }
    }

    fetchOrder()
  }, [params.orderId])

  const formattedOrderId = useMemo(() => {
    if (!order?.id) return params.orderId || ''
    // Simple PO-style formatting using last 6 chars of the UUID
    const suffix = order.id.slice(-6)
    return `PO-${suffix}`.toUpperCase()
  }, [order?.id, params.orderId])

  const retailerName = order?.consumer_name || 'Customer'

  const submittedAt = useMemo(() => {
    if (!order?.created_at) return ''
    const date = new Date(order.created_at)
    return date.toLocaleString(undefined, {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  }, [order?.created_at])

  const amount = useMemo(() => {
    if (order == null) return ''
    const total = order.total ?? 0
    const formatter = new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: 'KZT',
      maximumFractionDigits: 2
    })
    return formatter.format(total)
  }, [order])

  const deliveryWindow = useMemo(() => {
    if (!order?.delivery_date) return 'Not scheduled'
    const date = new Date(order.delivery_date)
    const datePart = date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: '2-digit'
    })

    const start = order.delivery_start_time ? order.delivery_start_time.slice(0, 5) : ''
    const end = order.delivery_end_time ? order.delivery_end_time.slice(0, 5) : ''

    if (start && end) {
      return `${datePart} · ${start} - ${end}`
    }

    return datePart
  }, [order?.delivery_date, order?.delivery_start_time, order?.delivery_end_time])

  const summary = useMemo(() => {
    if (!order?.items || order.items.length === 0) return 'No items found for this order'
    return order.items
      .map((item) => {
        const productName = item.product?.name || 'Item'
        return `${item.quantity} × ${productName}`
      })
      .join(' · ')
  }, [order?.items])

  const preferredSettlement = order?.preferred_settlement || 'Not specified'
  const notes = order?.notes || 'No special notes for this order'

  if (isLoading || !order) {
    return (
      <div className='flex items-center justify-center rounded-2xl border border-neutral-200 bg-white p-8 shadow-[0_30px_60px_rgba(15,23,42,0.08)]'>
        <p className='text-sm text-neutral-500'>Loading order details...</p>
      </div>
    )
  }

  return (
    <div className='space-y-8 rounded-2xl border border-neutral-200 bg-white p-8 shadow-[0_30px_60px_rgba(15,23,42,0.08)]'>
      <div className='flex flex-wrap items-center justify-between gap-4'>
        <div>
          <span className='rounded-full border border-primary-100 bg-primary-50 px-3 py-1 text-xs font-semibold text-primary-600'>
            {formattedOrderId}
          </span>
          <h1 className='mt-3 text-2xl font-semibold text-neutral-900'>{retailerName}</h1>
          <p className='text-sm text-neutral-500'>{submittedAt}</p>
        </div>
        <div className='flex gap-3'>
          <button
            onClick={() => router.back()}
            className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
          >
            Back
          </button>
          <Link
            href='/manager/orders'
            className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
          >
            Orders Overview
          </Link>
        </div>
      </div>

      <div className='grid gap-6 md:grid-cols-2'>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-5'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Summary</p>
          <p className='mt-2 text-sm text-neutral-600'>{summary}</p>
        </div>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-5'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Price</p>
          <p className='mt-2 text-lg font-semibold text-neutral-900'>{amount}</p>
          <p className='mt-1 text-sm text-neutral-500'>Preferred settlement: {preferredSettlement}</p>
        </div>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-5'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Delivery Window</p>
          <p className='mt-2 text-sm text-neutral-600'>{deliveryWindow}</p>
        </div>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-5'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Retailer Contact</p>
          <p className='mt-2 text-sm text-neutral-600'>
            {order.consumer_id}
          </p>
        </div>
      </div>

      <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-5'>
        <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Notes</p>
        <p className='mt-2 text-sm text-neutral-600'>{notes}</p>
      </div>

      <div className='flex flex-wrap gap-3'>
        <button className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'>Accept Order</button>
        <button className='rounded-xl border border-rose-300 px-4 py-2 text-sm font-semibold text-rose-500 transition hover:border-rose-400 hover:text-rose-600'>Reject Order</button>
      </div>
    </div>
  )
}
