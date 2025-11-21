'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useParams, useRouter } from 'next/navigation'
import toast from 'react-hot-toast'
import { Loader2 } from 'lucide-react'
import { getComplaint, getConversationMessages, resolveComplaint, type Complaint, type Message } from '@/lib/api/complaints'

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

/**
 * Get customer contact from complaint
 */
function getCustomerContact(complaint: Complaint): string {
  if (complaint.consumer?.phone_number) {
    return complaint.consumer.phone_number
  }
  if (complaint.consumer?.email) {
    return complaint.consumer.email
  }
  return 'N/A'
}

/**
 * Format date for display
 */
function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

/**
 * Generate history from conversation messages and complaint events
 */
function generateHistory(complaint: Complaint, messages: Message[]): string[] {
  const history: string[] = []
  
  // Add complaint creation
  history.push(`${formatDate(complaint.created_at)} · Complaint created`)
  
  // Add escalation if exists
  if (complaint.escalated_at) {
    history.push(`${formatDate(complaint.escalated_at)} · Issue escalated by sales representative`)
  }
  
  // Add resolution if exists
  if (complaint.resolved_at) {
    history.push(`${formatDate(complaint.resolved_at)} · Complaint resolved`)
  }
  
  // Add recent messages as history entries
  const recentMessages = messages
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 5)
  
  for (const msg of recentMessages) {
    const role = msg.sender_role === 'consumer' ? 'Customer' : 'Sales Representative'
    history.push(`${formatDate(msg.created_at)} · ${role}: ${msg.content.substring(0, 50)}${msg.content.length > 50 ? '...' : ''}`)
  }
  
  return history.reverse()
}

export default function ManagerComplaintDetailPage() {
  const params = useParams<{ id: string }>()
  const router = useRouter()
  const [complaint, setComplaint] = useState<Complaint | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isResolving, setIsResolving] = useState(false)
  const [resolution, setResolution] = useState('')

  useEffect(() => {
    const fetchData = async () => {
      if (!params.id || typeof params.id !== 'string') {
        toast.error('Invalid complaint ID')
        router.push('/manager/complaints')
        return
      }

      try {
        setIsLoading(true)
        const [complaintData, messagesData] = await Promise.all([
          getComplaint(params.id),
          getComplaint(params.id).then(c => getConversationMessages(c.conversation_id))
        ])
        setComplaint(complaintData)
        setMessages(messagesData)
      } catch (error: any) {
        console.error('Failed to fetch complaint:', error)
        toast.error(error.message || 'Failed to load complaint')
        router.push('/manager/complaints')
      } finally {
        setIsLoading(false)
      }
    }

    fetchData()
  }, [params.id, router])

  const handleResolve = async () => {
    if (!complaint || !resolution.trim() || resolution.trim().length < 10) {
      toast.error('Please provide a resolution (minimum 10 characters)')
      return
    }

    try {
      setIsResolving(true)
      const updated = await resolveComplaint(complaint.id, resolution)
      setComplaint(updated)
      toast.success('Complaint resolved successfully')
    } catch (error: any) {
      console.error('Failed to resolve complaint:', error)
      toast.error(error.message || 'Failed to resolve complaint')
    } finally {
      setIsResolving(false)
    }
  }

  if (isLoading || !complaint) {
    return (
      <div className='flex items-center justify-center p-10'>
        <Loader2 className='h-8 w-8 animate-spin text-neutral-400' />
        <p className='ml-4 text-sm text-neutral-500'>Loading complaint details...</p>
      </div>
    )
  }

  const isResolved = complaint.status === 'resolved' || complaint.status === 'closed'
  const history = generateHistory(complaint, messages)

  return (
    <div className='space-y-8 rounded-2xl border border-neutral-200 bg-white p-8 shadow-[0_30px_60px_rgba(15,23,42,0.08)]'>
      <div className='flex flex-wrap items-center justify-between gap-4'>
        <div>
          <span className='rounded-full border border-primary-100 bg-primary-50 px-3 py-1 text-xs font-semibold text-primary-600'>
            {formatComplaintId(complaint.id)}
          </span>
          <h1 className='mt-3 text-2xl font-semibold text-neutral-900'>{getCustomerName(complaint)}</h1>
          <div className='mt-1 flex flex-wrap items-center gap-3 text-sm text-neutral-500'>
            <span>{formatDate(complaint.created_at)}</span>
            {complaint.order_id ? (
              <span className='rounded-full border border-neutral-200 bg-neutral-100 px-3 py-1 text-xs font-semibold text-neutral-600'>
                Order {complaint.order_id.substring(0, 8).toUpperCase()}
              </span>
            ) : null}
            <span className={`rounded-full px-3 py-1 text-xs font-semibold text-white ${
              isResolved ? 'bg-emerald-500' : 'bg-amber-500'
            }`}>
              {complaint.status}
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
        </div>
        <div className='flex gap-3'>
          <button
            onClick={() => router.back()}
            className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
          >
            Back
          </button>
          <Link 
            href='/manager/complaints' 
            className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
          >
            All Complaints
          </Link>
        </div>
      </div>

      <section className='grid gap-6 md:grid-cols-2'>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-6'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Issue Summary</p>
          <p className='mt-3 text-sm font-semibold text-neutral-900'>{complaint.title}</p>
          <p className='mt-2 text-sm text-neutral-600'>{complaint.description}</p>
        </div>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-6'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Requested Resolution</p>
          <p className='mt-3 text-sm text-neutral-600'>
            {complaint.resolution || 'No specific resolution requested. Please review the issue and provide a solution.'}
          </p>
        </div>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-6'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Contact</p>
          <p className='mt-3 text-sm text-neutral-600'>{getCustomerContact(complaint)}</p>
        </div>
        <div className='rounded-2xl border border-neutral-100 bg-neutral-50 p-6'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>History</p>
          <ul className='mt-3 space-y-2 text-sm text-neutral-600'>
            {history.length > 0 ? (
              history.map((entry, index) => (
                <li key={index}>{entry}</li>
              ))
            ) : (
              <li className='text-neutral-400'>No history available</li>
            )}
          </ul>
        </div>
      </section>

      {complaint.resolution && (
        <section className='rounded-2xl border border-neutral-100 bg-neutral-50 p-6'>
          <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Resolution</p>
          <p className='mt-3 text-sm text-neutral-600'>{complaint.resolution}</p>
          {complaint.resolved_at && (
            <p className='mt-2 text-xs text-neutral-500'>
              Resolved on: {formatDate(complaint.resolved_at)}
            </p>
          )}
        </section>
      )}

      <section className='rounded-2xl border border-neutral-100 bg-neutral-50 p-6'>
        <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Manager Response</p>
        <textarea
          value={resolution}
          onChange={(e) => setResolution(e.target.value)}
          className='mt-3 h-28 w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm text-neutral-700 shadow-sm transition focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-100'
          placeholder='Outline your decision. For example: agree to issue replacement shipment or propose alternative compensation.'
          disabled={isResolved || isResolving}
        />
        {!isResolved && (
          <p className='mt-2 text-xs text-neutral-500'>
            Minimum 10 characters required to resolve the complaint.
          </p>
        )}
      </section>

      {!isResolved ? (
        <div className='flex flex-wrap gap-3'>
          <button
            onClick={handleResolve}
            disabled={isResolving || !resolution.trim() || resolution.trim().length < 10}
            className='rounded-xl bg-emerald-500 px-4 py-3 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600 disabled:cursor-not-allowed disabled:bg-neutral-300'
          >
            {isResolving ? 'Resolving...' : 'Resolve Complaint'}
          </button>
          <Link
            href={`/manager/complaints/${complaint.id}/chat`}
            className='rounded-xl border border-neutral-200 px-4 py-3 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
          >
            Start Chat with Client
          </Link>
        </div>
      ) : null}
    </div>
  )
}
