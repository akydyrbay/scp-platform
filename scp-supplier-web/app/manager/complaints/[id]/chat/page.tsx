'use client'

import { useEffect, useRef, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { ArrowLeft, Image as ImageIcon, Check, CheckCheck, Loader2, User } from 'lucide-react'
import toast from 'react-hot-toast'
import { getComplaint, getConversationMessages, sendMessage, markMessagesAsRead, type Complaint, type Message } from '@/lib/api/complaints'
import { useAuthStore } from '@/lib/store/auth-store'

type UIMessage = {
  id: string
  author: 'client' | 'manager'
  timestamp: string
  content: string
  read: boolean
  date: string
  senderName?: string
}

const readIcon = (read: boolean) =>
  read ? <CheckCheck className='h-3 w-3' /> : <Check className='h-3 w-3' />

// Map API message to UI message format
function mapMessageToUI(message: Message, currentUserId: string): UIMessage {
  // Backend may return 'timestamp' or 'created_at' - handle both
  const dateString = (message as any).timestamp || message.created_at
  
  // Parse the date
  const date = new Date(dateString)
  
  // Validate date and format it
  let dateStr = 'Invalid Date'
  let timeStr = 'Invalid Time'
  
  if (!isNaN(date.getTime())) {
    dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    timeStr = date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
  } else {
    // If date parsing fails, use current time as fallback
    const now = new Date()
    dateStr = now.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    timeStr = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
    console.warn('Failed to parse message date:', dateString, 'Using current time as fallback')
  }
  
  // Determine if message is from manager (current user) or client
  // Note: Backend stores manager/owner as 'sales_rep' in DB, but should return original role
  // Also check by comparing sender_id with current user ID as fallback
  const senderRole = message.sender_role || ''
  const isManager = 
    senderRole === 'manager' || 
    senderRole === 'owner' || 
    senderRole === 'sales_rep' ||
    (currentUserId && message.sender_id === currentUserId)
  
  return {
    id: message.id,
    author: isManager ? 'manager' : 'client',
    timestamp: `${dateStr} · ${timeStr}`,
    content: message.content,
    read: message.is_read ?? false,
    date: dateStr,
    senderName: (message as any).sender_name || undefined
  }
}

// Group messages by date
function groupMessagesByDate(messages: UIMessage[]): Record<string, UIMessage[]> {
  return messages.reduce<Record<string, UIMessage[]>>((acc, message) => {
    const key = message.date
    acc[key] = acc[key] ? [...acc[key], message] : [message]
    return acc
  }, {})
}

export default function ManagerComplaintChatPage () {
  const params = useParams<{ id: string }>()
  const router = useRouter()
  const { user } = useAuthStore()
  const complaintId = params.id as string
  
  const [complaint, setComplaint] = useState<Complaint | null>(null)
  const [messages, setMessages] = useState<UIMessage[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSending, setIsSending] = useState(false)
  const [draft, setDraft] = useState('')
  const endRef = useRef<HTMLDivElement | null>(null)
  const pollIntervalRef = useRef<NodeJS.Timeout | null>(null)

  // Fetch complaint and messages
  useEffect(() => {
    if (!complaintId) {
      toast.error('Invalid complaint ID')
      router.push('/manager/complaints')
      return
    }

    const fetchData = async () => {
      try {
        setIsLoading(true)
        
        // Fetch complaint to get conversation_id and details
        const complaintData = await getComplaint(complaintId)
        setComplaint(complaintData)
        
        // Fetch messages if conversation_id exists
        if (complaintData.conversation_id) {
          const apiMessages = await getConversationMessages(complaintData.conversation_id)
          const uiMessages = apiMessages.map(msg => mapMessageToUI(msg, user?.id || ''))
          setMessages(uiMessages)
          
          // Mark messages as read
          await markMessagesAsRead(complaintData.conversation_id)
        }
      } catch (error: any) {
        console.error('Failed to fetch complaint chat data:', error)
        toast.error(error.message || 'Failed to load chat')
        router.push('/manager/complaints')
      } finally {
        setIsLoading(false)
      }
    }

    fetchData()
  }, [complaintId, router, user?.id])

  // Poll for new messages every 5 seconds
  useEffect(() => {
    if (!complaint?.conversation_id || isLoading) return

    const pollMessages = async () => {
      try {
        const apiMessages = await getConversationMessages(complaint.conversation_id)
        const uiMessages = apiMessages.map(msg => mapMessageToUI(msg, user?.id || ''))
        setMessages(uiMessages)
      } catch (error) {
        console.error('Failed to poll messages:', error)
      }
    }

    // Poll immediately, then every 5 seconds
    pollMessages()
    pollIntervalRef.current = setInterval(pollMessages, 5000)

    return () => {
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current)
      }
    }
  }, [complaint?.conversation_id, isLoading, user?.id])

  // Scroll to bottom when messages change
  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!draft.trim() || !complaint?.conversation_id || isSending) return

    try {
      setIsSending(true)
      
      // Send message
      const newMessage = await sendMessage(
        complaint.conversation_id,
        draft.trim(),
        complaint.order_id || undefined
      )
      
      // Add new message to list
      const uiMessage = mapMessageToUI(newMessage, user?.id || '')
      setMessages(prev => [...prev, uiMessage])
      
      // Clear draft
      setDraft('')
      
      // Mark messages as read
      await markMessagesAsRead(complaint.conversation_id)
      
      toast.success('Message sent')
    } catch (error: any) {
      console.error('Failed to send message:', error)
      toast.error(error.message || 'Failed to send message')
    } finally {
      setIsSending(false)
    }
  }

  const getCustomerName = (complaint: Complaint): string => {
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

  const groupedMessages = groupMessagesByDate(messages)

  if (isLoading) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <div className='flex items-center gap-3'>
          <Loader2 className='h-6 w-6 animate-spin text-neutral-400' />
          <p className='text-sm text-neutral-500'>Loading chat...</p>
        </div>
      </div>
    )
  }

  if (!complaint) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <p className='text-sm text-neutral-500'>Complaint not found</p>
      </div>
    )
  }

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
            <h1 className='mt-2 text-xl font-semibold text-neutral-900'>{getCustomerName(complaint)}</h1>
            <p className='text-sm text-neutral-500'>Complaint {complaint.id.substring(0, 8).toUpperCase()}</p>
          </div>
          <div className='space-y-2 text-sm text-neutral-600'>
            <p><strong>Issue</strong></p>
            <p>{complaint.title}</p>
            <p className='mt-2 text-neutral-500'>{complaint.description}</p>
            {complaint.order_id && (
              <p className='mt-4'><strong>Order ID</strong></p>
            )}
            {complaint.order_id && (
              <p className='text-neutral-500'>{complaint.order_id.substring(0, 8).toUpperCase()}</p>
            )}
            {complaint.resolution && (
              <>
                <p className='mt-4'><strong>Resolution</strong></p>
                <p className='text-neutral-500'>{complaint.resolution}</p>
              </>
            )}
          </div>
        </aside>

        <div className='flex flex-col gap-4 rounded-3xl border border-neutral-200 bg-[#e9f2ff] p-6 shadow-inner'>
          <div className='flex-1 overflow-y-auto rounded-2xl bg-white/60 p-6 shadow-inner'>
            <div className='space-y-5'>
              {messages.length === 0 ? (
                <div className='flex items-center justify-center py-10'>
                  <p className='text-sm text-neutral-500'>No messages yet. Start the conversation!</p>
                </div>
              ) : (
                Object.entries(groupedMessages).map(([date, dateMessages]) => (
                  <div key={date} className='space-y-4'>
                    <div className='flex justify-center'>
                      <span className='rounded-full bg-neutral-200 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.2em] text-neutral-600'>
                        {date}
                      </span>
                    </div>
                    {dateMessages.map(message => {
                      // Safely extract time from timestamp, with fallback
                      const timestampParts = message.timestamp.split(' · ')
                      const time = timestampParts.length >= 2 ? timestampParts[1] : message.timestamp
                      const isManager = message.author === 'manager'
                      
                      return (
                        <div
                          key={message.id}
                          className={`flex items-end gap-2 ${isManager ? 'flex-row-reverse' : 'flex-row'}`}
                        >
                          {/* Avatar/Icon */}
                          <div
                            className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${
                              isManager
                                ? 'bg-primary-600 text-white'
                                : 'bg-neutral-200 text-neutral-600'
                            }`}
                          >
                            <User className='h-4 w-4' />
                          </div>
                          
                          {/* Message Bubble */}
                          <div className={`flex max-w-[65%] flex-col ${isManager ? 'items-end' : 'items-start'}`}>
                            {/* Sender Label */}
                            <span
                              className={`mb-1 text-xs font-semibold ${
                                isManager ? 'text-primary-600' : 'text-neutral-500'
                              }`}
                            >
                              {isManager ? 'You' : (message.senderName || 'Customer')}
                            </span>
                            
                            {/* Message Content */}
                            <div
                              className={`rounded-3xl px-4 py-3 text-sm shadow-lg ${
                                isManager
                                  ? 'bg-primary-500 text-white'
                                  : 'bg-white text-neutral-800 border border-neutral-200'
                              }`}
                            >
                              <p className='whitespace-pre-wrap break-words'>{message.content}</p>
                              <div className={`mt-2 flex items-center gap-2 text-[10px] uppercase tracking-[0.2em] ${
                                isManager ? 'justify-end' : 'justify-start'
                              }`}>
                                <span className={isManager ? 'text-white/70' : 'text-neutral-400'}>{time}</span>
                                {isManager ? (
                                  <span className={message.read ? 'text-white' : 'text-white/70'}>
                                    {readIcon(message.read)}
                                  </span>
                                ) : null}
                              </div>
                            </div>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                ))
              )}
              <div ref={endRef} />
            </div>
          </div>

          <form onSubmit={handleSend} className='rounded-2xl border border-neutral-200 bg-white p-3 shadow-[0_12px_32px_rgba(15,23,42,0.08)]'>
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
                disabled={isSending}
              />
            </div>
            <div className='mt-2 flex justify-end gap-3'>
              <button
                type='button'
                onClick={() => setDraft('')}
                className='rounded-xl border border-neutral-200 px-3 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
                disabled={isSending}
              >
                Cancel
              </button>
              <button
                type='submit'
                className='rounded-xl bg-primary-500 px-5 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(59,130,246,0.25)] transition hover:bg-primary-600 disabled:opacity-60'
                disabled={!draft.trim() || isSending}
              >
                {isSending ? 'Sending...' : 'Send'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
