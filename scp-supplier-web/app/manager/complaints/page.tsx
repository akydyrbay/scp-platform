'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { Loader2 } from 'lucide-react'
import { PageHeader } from '@/components/ui/page-header'
import { getComplaints, type Complaint } from '@/lib/api/complaints'

type ComplaintStatus = 'open' | 'escalated' | 'resolved' | 'closed'
type UIFilterStatus = 'New' | 'Resolved'

/**
 * Map backend status to UI display status
 */
function mapStatusToUI(status: string): UIFilterStatus {
  if (status === 'resolved' || status === 'closed') {
    return 'Resolved'
  }
  return 'New'
}

const uiFilters: UIFilterStatus[] = ['New', 'Resolved']

/**
 * Format complaint ID for display
 */
function formatComplaintId(id: string): string {
  return `CMP-${id.substring(0, 8).toUpperCase()}`
}

/**
 * Get customer name from complaint
 */
function getCustomerName(complaint: Complaint): string {
  if (complaint.consumer) {
    if (complaint.consumer.company_name) {
      return complaint.consumer.company_name
    }
    if (complaint.consumer.first_name || complaint.consumer.last_name) {
      return `${complaint.consumer.first_name || ''} ${complaint.consumer.last_name || ''}`.trim()
    }
    return complaint.consumer.email
  }
  return `Consumer ${complaint.consumer_id.substring(0, 8)}`
}

export default function ManagerComplaintsPage() {
  const [activeFilter, setActiveFilter] = useState<'New' | 'Resolved'>('New')
  const [complaints, setComplaints] = useState<Complaint[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchComplaints = async () => {
      try {
        setIsLoading(true)
        // Map UI filter to backend status
        const status = activeFilter === 'New' ? undefined : 'resolved'
        const data = await getComplaints(1, 100, status)
        setComplaints(Array.isArray(data.results) ? data.results : [])
      } catch (error: any) {
        console.error('Failed to fetch complaints:', error)
        toast.error(error.message || 'Failed to load complaints')
        setComplaints([])
      } finally {
        setIsLoading(false)
      }
    }
    
    fetchComplaints()
  }, [activeFilter])

  const filteredComplaints = useMemo(() => {
    return complaints.filter(complaint => {
      const uiStatus = mapStatusToUI(complaint.status)
      return uiStatus === activeFilter
    })
  }, [complaints, activeFilter])

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Complaints'
        description='Track escalations from distributors, assign next steps, and resolve critical issues quickly.'
      />

      <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
        <div className='flex flex-wrap items-center gap-3'>
          {uiFilters.map(filter => (
            <button
              key={filter}
              onClick={() => setActiveFilter(filter)}
              className={`rounded-xl border px-4 py-2 text-sm font-semibold transition ${
                activeFilter === filter
                  ? filter === 'New'
                    ? 'border-amber-200 bg-amber-50 text-amber-600 shadow-[0_12px_24px_rgba(251,191,36,0.25)]'
                    : 'border-emerald-200 bg-emerald-50 text-emerald-600 shadow-[0_12px_24px_rgba(16,185,129,0.25)]'
                  : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-100 hover:text-primary-500'
              }`}
            >
              {filter}
            </button>
          ))}
        </div>
      </div>

      <div className='grid gap-4'>
        {isLoading ? (
          <div className='flex items-center justify-center p-10'>
            <Loader2 className='h-8 w-8 animate-spin text-neutral-400' />
            <p className='ml-4 text-sm text-neutral-500'>Loading complaints...</p>
          </div>
        ) : filteredComplaints.length === 0 ? (
          <div className='rounded-2xl border border-neutral-100 bg-white p-6 text-center text-neutral-500 shadow-sm'>
            No complaints found for the selected filter.
          </div>
        ) : (
          filteredComplaints.map(complaint => (
            <div key={complaint.id} className='flex flex-wrap gap-6 rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_10px_30px_rgba(15,23,42,0.08)]'>
              <div className='flex flex-1 flex-col gap-3'>
                <div className='flex flex-wrap items-center gap-3'>
                  <span className='rounded-full border border-primary-100 bg-primary-50 px-3 py-1 text-xs font-semibold text-primary-600'>
                    {formatComplaintId(complaint.id)}
                  </span>
                  <p className='text-sm font-semibold text-neutral-900'>{getCustomerName(complaint)}</p>
                  {complaint.order_id ? (
                    <span className='rounded-full border border-neutral-200 bg-neutral-100 px-3 py-1 text-xs font-semibold text-neutral-600'>
                      Order {complaint.order_id.substring(0, 8).toUpperCase()}
                    </span>
                  ) : null}
                  <span className={`rounded-full px-3 py-1 text-xs font-semibold text-white ${
                    mapStatusToUI(complaint.status) === 'New' ? 'bg-amber-500' : 'bg-emerald-500'
                  }`}>
                    {mapStatusToUI(complaint.status)}
                  </span>
                  {complaint.priority && (
                    <span className={`rounded-full px-3 py-1 text-xs font-semibold ${
                      complaint.priority === 'urgent' ? 'bg-rose-100 text-rose-700' :
                      complaint.priority === 'high' ? 'bg-orange-100 text-orange-700' :
                      complaint.priority === 'medium' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-blue-100 text-blue-700'
                    }`}>
                      {complaint.priority}
                    </span>
                  )}
                </div>
                <p className='text-sm font-semibold text-neutral-900'>{complaint.title}</p>
                <p className='text-sm text-neutral-600'>{complaint.description}</p>
                <p className='text-xs text-neutral-500'>
                  Created: {new Date(complaint.created_at).toLocaleDateString('en-US', { 
                    year: 'numeric', 
                    month: 'short', 
                    day: 'numeric' 
                  })}
                </p>
              </div>
              <div className='flex items-start gap-3'>
                <Link
                  href={`/manager/complaints/${complaint.id}`}
                  className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
                >
                  View Details
                </Link>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
