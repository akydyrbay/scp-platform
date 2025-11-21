'use client'

import { useEffect, useState, useMemo } from 'react'
import { PageHeader } from '@/components/ui/page-header'
import { Button } from '@/components/ui/button'
import toast from 'react-hot-toast'
import { getConsumerLinks, approveLink, rejectLink, blockLink, type ConsumerLink } from '@/lib/api/consumer-links'

type LinkStatus = 'pending' | 'accepted' | 'completed' | 'rejected' | 'cancelled'

const statusFilters: LinkStatus[] = ['pending', 'accepted', 'completed', 'rejected', 'cancelled']

const statusStyles: Record<LinkStatus, string> = {
  pending: 'border-amber-200 bg-amber-50 text-amber-600 shadow-[0_12px_24px_rgba(251,191,36,0.18)]',
  accepted: 'border-emerald-200 bg-emerald-50 text-emerald-600 shadow-[0_12px_24px_rgba(16,185,129,0.18)]',
  completed: 'border-emerald-300 bg-emerald-50 text-emerald-700 shadow-[0_12px_24px_rgba(16,185,129,0.18)]',
  rejected: 'border-rose-200 bg-rose-50 text-rose-600 shadow-[0_12px_24px_rgba(239,68,68,0.18)]',
  cancelled: 'border-neutral-300 bg-neutral-100 text-neutral-600 shadow-[0_12px_24px_rgba(148,163,184,0.18)]',
}

const statusOutlineStyles: Record<LinkStatus, string> = {
  pending: 'border-amber-200 bg-amber-50 text-amber-700',
  accepted: 'border-emerald-200 bg-emerald-50 text-emerald-700',
  completed: 'border-emerald-300 bg-emerald-50 text-emerald-800',
  rejected: 'border-rose-200 bg-rose-50 text-rose-700',
  cancelled: 'border-neutral-300 bg-neutral-100 text-neutral-600',
}

function mapStatus(status: string): LinkStatus {
  const normalized = status.toLowerCase()

  if (normalized === 'pending') return 'pending'
  if (normalized === 'accepted' || normalized === 'approved') return 'accepted'
  if (normalized === 'completed') return 'completed'
  if (normalized === 'rejected') return 'rejected'
  if (normalized === 'cancelled' || normalized === 'canceled' || normalized === 'blocked') return 'cancelled'

  return 'pending'
}

export default function ManagerLinksPage() {
  const [activeFilter, setActiveFilter] = useState<LinkStatus>('pending')
  const [links, setLinks] = useState<ConsumerLink[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchLinks = async () => {
      try {
        setIsLoading(true)
        const data = await getConsumerLinks(1, 100)
        setLinks(Array.isArray(data.results) ? data.results : [])
      } catch (error) {
        console.error('Failed to fetch consumer links:', error)
        toast.error('Failed to load consumer links')
        setLinks([])
      } finally {
        setIsLoading(false)
      }
    }

    fetchLinks()
  }, [])

  const filteredLinks = useMemo(() => {
    return links.filter(link => mapStatus(link.status) === activeFilter)
  }, [links, activeFilter])

  const handleApprove = async (id: string) => {
    try {
      await approveLink(id)
      setLinks(links.map(link =>
        link.id === id ? { ...link, status: 'accepted' } : link
      ))
      toast.success('Consumer link accepted successfully')
    } catch (error: any) {
      console.error('Failed to approve link:', error)
      const message = error.response?.data?.error?.message || 'Failed to approve link'
      toast.error(message)
    }
  }

  const handleReject = async (id: string) => {
    if (!confirm('Are you sure you want to reject this consumer link request?')) return

    try {
      await rejectLink(id)
      setLinks(links.map(link => 
        link.id === id ? { ...link, status: 'rejected' } : link
      ))
      toast.success('Consumer link rejected')
    } catch (error: any) {
      console.error('Failed to reject link:', error)
      const message = error.response?.data?.error?.message || 'Failed to reject link'
      toast.error(message)
    }
  }

  const handleBlock = async (id: string) => {
    if (!confirm('Are you sure you want to block this consumer? This action cannot be undone.')) return

    try {
      await blockLink(id)
      setLinks(links.map(link =>
        link.id === id ? { ...link, status: 'cancelled' } : link
      ))
      toast.success('Consumer link cancelled successfully')
    } catch (error: any) {
      console.error('Failed to block link:', error)
      const message = error.response?.data?.error?.message || 'Failed to block link'
      toast.error(message)
    }
  }

  if (isLoading) {
    return (
      <div className='flex w-full justify-center'>
        <div className='text-sm text-neutral-500'>Loading consumer links...</div>
      </div>
    )
  }

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Consumer Link Requests'
        description='Manage consumer requests to link with your supplier account. Approve or reject link requests to control access to your products.'
      />

      <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
        <div className='flex flex-wrap items-center gap-3 mb-6'>
                {statusFilters.map(filter => (
            <button
              key={filter}
              onClick={() => setActiveFilter(filter)}
              className={`rounded-xl border px-4 py-2 text-sm font-semibold transition capitalize ${
                activeFilter === filter
                  ? statusStyles[filter]
                  : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-100 hover:text-primary-500'
              }`}
            >
              {filter}
              <span className='ml-2 rounded-full bg-neutral-100 px-2 py-0.5 text-xs font-medium text-neutral-500'>
                {links.filter(l => mapStatus(l.status) === filter).length}
              </span>
            </button>
          ))}
        </div>

        <div className='space-y-4'>
          {filteredLinks.length === 0 ? (
            <div className='rounded-2xl border border-dashed border-neutral-200 bg-neutral-50 p-10 text-center text-sm text-neutral-500'>
              No consumer links found with status "{activeFilter}".
            </div>
          ) : (
            filteredLinks.map(link => {
              const status = mapStatus(link.status)
              return (
                <div
                  key={link.id}
                  className='flex flex-wrap items-center justify-between gap-4 rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_10px_30px_rgba(15,23,42,0.08)]'
                >
                  <div className='flex-1'>
                    <div className='flex items-center gap-3 mb-2'>
                      <span className={`rounded-full border px-3 py-1 text-xs font-semibold capitalize ${statusOutlineStyles[status]}`}>
                        {status}
                      </span>
                      <p className='text-sm font-semibold text-neutral-900'>Consumer ID: {link.consumer_id}</p>
                    </div>
                    <p className='text-xs text-neutral-500'>
                      Requested: {new Date(link.requested_at).toLocaleDateString('en-US', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </p>
                    {link.approved_at && (
                      <p className='text-xs text-emerald-600'>
                        Approved: {new Date(link.approved_at).toLocaleDateString('en-US')}
                      </p>
                    )}
                    {link.rejected_at && (
                      <p className='text-xs text-rose-600'>
                        Rejected: {new Date(link.rejected_at).toLocaleDateString('en-US')}
                      </p>
                    )}
                  </div>

                  <div className='flex flex-wrap gap-3'>
                    {status === 'pending' && (
                      <>
                        <Button
                          onClick={() => handleApprove(link.id)}
                          className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'
                        >
                          Approve
                        </Button>
                        <Button
                          onClick={() => handleReject(link.id)}
                          variant='secondary'
                          className='rounded-xl border border-rose-300 px-4 py-2 text-sm font-semibold text-rose-600 transition hover:border-rose-400 hover:text-rose-700'
                        >
                          Reject
                        </Button>
                      </>
                    )}
                    {status === 'accepted' && (
                      <Button
                        onClick={() => handleBlock(link.id)}
                        variant='secondary'
                        className='rounded-xl border border-neutral-300 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-neutral-400 hover:text-neutral-700'
                      >
                        Block
                      </Button>
                    )}
                    {status === 'rejected' && (
                      <Button
                        onClick={() => handleApprove(link.id)}
                        className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'
                      >
                        Approve
                      </Button>
                    )}
                  </div>
                </div>
              )
            })
          )}
        </div>
      </div>
    </div>
  )
}

