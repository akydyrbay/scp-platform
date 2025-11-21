'use client'

import { useEffect, useRef, useState } from 'react'
import Link from 'next/link'
import { useParams, useRouter } from 'next/navigation'
import { ArrowLeft, Image as ImageIcon, Check, CheckCheck } from 'lucide-react'

import { complaintTickets } from '@/app/manager/complaints/page'

const threads = complaintTickets.reduce<Record<string, typeof complaintTickets[number]>>((acc, ticket) => {
  acc[ticket.id] = ticket
  return acc
}, {})

const mockMessages = [
  { id: 1, author: 'client', timestamp: 'Nov 10 · 13:45', content: 'Could you confirm if the replacement shipment can leave today?', read: true },
  { id: 2, author: 'manager', timestamp: 'Nov 10 · 13:47', content: 'I am reviewing this now. Do you prefer delivery before 10AM?', read: true },
  { id: 3, author: 'client', timestamp: 'Nov 10 · 13:50', content: 'Yes, morning delivery works best for us.', read: true },
  { id: 4, author: 'manager', timestamp: 'Nov 10 · 13:52', content: 'Noted. I will coordinate with logistics and get back shortly.', read: false }
] as const

const groupedMessages = mockMessages.reduce<Record<string, typeof mockMessages>>( (acc, message) => {
  const key = message.timestamp.split(' · ')[0]
  acc[key] = acc[key] ? [...acc[key], message] : [message]
  return acc
}, {})

const readIcon = {
  true: <CheckCheck className='h-3 w-3' />,
  false: <Check className='h-3 w-3' />
}

export default function ManagerComplaintChatPage () {
  const params = useParams<{ id: string }>()
  const router = useRouter()
  const [draft, setDraft] = useState('')
  const endRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [])

  const complaint = threads[params.id ?? ''] ?? complaintTickets[0]

  return (
    <div className='rounded-3xl border border-neutral-200 bg-[#f6f7fb] p-6 shadow-[0_30px_60px_rgba(15,23,42,0.08)]'>
      <div className='grid gap-6 xl:grid-cols-[320px_minmax(0,1fr)]'>
        <aside className='space-y-5 rounded-3xl border border-neutral-200 bg-white p-5 shadow-sm'>
          <button
            onClick={() => router.back()}
            className='inline-flex items-center gap-2 text-sm font-semibold text-neutral-600 transition hover:text-primary-500'
          >
            <ArrowLeft className='h-4 w-4' />
            Back
          </button>
          <div>
            <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Chat</p>
            <h1 className='mt-2 text-xl font-semibold text-neutral-900'>{complaint.customer}</h1>
            <p className='text-sm text-neutral-500'>Complaint {complaint.id}</p>
          </div>
          <div className='space-y-2 text-sm text-neutral-600'>
            <p><strong>Issue</strong></p>
            <p>Review replacement shipment timing and confirm chilled logistics availability.</p>
            <p className='mt-4'><strong>Requested Resolution</strong></p>
            <p>Replacement shipment before 10AM or partial refund equivalent to ₸ 1,250,000.</p>
          </div>
        </aside>

        <div className='flex flex-col gap-4 rounded-3xl border border-neutral-200 bg-[#e9f2ff] p-6 shadow-inner'>
          <div className='flex-1 overflow-y-auto rounded-2xl bg-white/60 p-6 shadow-inner'>
            <div className='space-y-5'>
              {Object.entries(groupedMessages).map(([date, messages]) => (
                <div key={date} className='space-y-4'>
                  <div className='flex justify-center'>
                    <span className='rounded-full bg-neutral-200 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.2em] text-neutral-600'>
                      {date}
                    </span>
                  </div>
                  {messages.map(message => {
                    const [, time] = message.timestamp.split(' · ')
                    return (
                      <div
                        key={message.id}
                        className={`flex ${message.author === 'manager' ? 'justify-end' : 'justify-start'}`}
                      >
                        <div
                          className={`max-w-[65%] rounded-3xl px-4 py-3 text-sm shadow ${
                            message.author === 'manager'
                              ? 'bg-primary-500 text-white'
                              : 'bg-white text-neutral-700'
                          }`}
                        >
                          <p>{message.content}</p>
                          <div className='mt-2 flex items-center justify-end gap-2 text-[10px] uppercase tracking-[0.2em]'>
                            <span className={message.author === 'manager' ? 'text-white/70' : 'text-neutral-400'}>{time}</span>
                            {message.author === 'manager' ? (
                              <span className={message.read ? 'text-white' : 'text-white/70'}>
                                {readIcon[message.read]}
                              </span>
                            ) : null}
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>
              ))}
              <div ref={endRef} />
            </div>
          </div>

          <form className='rounded-2xl border border-neutral-200 bg-white p-3 shadow-[0_12px_32px_rgba(15,23,42,0.08)]'>
            <div className='flex items-center gap-3'>
              <label className='inline-flex h-10 w-10 cursor-pointer items-center justify-center rounded-2xl border border-neutral-200 bg-neutral-50 text-neutral-500 transition hover:border-primary-200 hover:text-primary-500'>
                <ImageIcon className='h-5 w-5' />
                <input type='file' accept='image/*' className='hidden' />
              </label>
              <textarea
                value={draft}
                onChange={event => setDraft(event.target.value)}
                placeholder='Write a message to the client…'
                className='h-20 w-full rounded-2xl border border-neutral-200 bg-white px-3 py-2 text-sm text-neutral-700 shadow-sm transition focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-100'
              />
            </div>
            <div className='mt-2 flex justify-end gap-3'>
              <button
                type='button'
                onClick={() => setDraft('')}
                className='rounded-xl border border-neutral-200 px-3 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
              >
                Cancel
              </button>
              <button
                type='submit'
                className='rounded-xl bg-primary-500 px-5 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(59,130,246,0.25)] transition hover:bg-primary-600 disabled:opacity-60'
                disabled={!draft.trim()}
              >
                Send
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
