'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store/auth-store'
import { logout } from '@/lib/api/auth'
import { getCurrentSupplier, type SupplierProfile } from '@/lib/api/suppliers'
import { PageHeader } from '@/components/ui/page-header'
import { SectionCard } from '@/components/ui/section-card'
import { Button } from '@/components/ui/button'
import toast from 'react-hot-toast'

export default function OwnerSettingsPage() {
  const router = useRouter()
  const { user } = useAuthStore()
  const [supplier, setSupplier] = useState<SupplierProfile | null>(null)
  const [isLoadingSupplier, setIsLoadingSupplier] = useState(true)

  useEffect(() => {
    let isMounted = true

    const fetchSupplier = async () => {
      try {
        const data = await getCurrentSupplier()
        if (isMounted) {
          setSupplier(data)
        }
      } catch (error) {
        console.error('Failed to load supplier profile:', error)
        if (isMounted) {
          setSupplier(null)
        }
      } finally {
        if (isMounted) {
          setIsLoadingSupplier(false)
        }
      }
    }

    fetchSupplier()

    return () => {
      isMounted = false
    }
  }, [])

  const handleSignOut = async () => {
    try {
      const { setUser } = useAuthStore.getState()

      setUser(null)

      await logout()
      toast.success('Logged out successfully')
      router.replace('/login')
      setTimeout(() => {
        if (window.location.pathname !== '/login') {
          window.location.replace('/login')
        }
      }, 100)
    } catch (error) {
      console.error('Logout error:', error)
      const { setUser } = useAuthStore.getState()
      setUser(null)
      router.replace('/login')
    }
  }

  if (!user) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <div className='text-sm text-neutral-500'>Loading...</div>
      </div>
    )
  }

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Account Settings'
        description='Manage your account information and preferences'
      />

      <SectionCard
        title='Personal Information'
        action={(
          <Button
            variant='secondary'
            onClick={() => toast.success('Edit profile feature coming soon')}
            className='rounded-lg border border-neutral-200 px-4 py-2 text-sm font-medium text-primary-500 transition hover:bg-primary-50 hover:text-primary-600'
          >
            Edit Profile
          </Button>
        )}
      >
        <div className='grid gap-4 md:grid-cols-2'>
          <div>
            <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Name</p>
            <p className='mt-1 text-lg font-semibold text-neutral-900'>{user.name}</p>
          </div>
          <div>
            <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Email</p>
            <p className='mt-1 text-lg font-semibold text-neutral-900'>{user.email}</p>
          </div>
          <div>
            <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Role</p>
            <p className='mt-1 text-lg font-semibold text-neutral-900 capitalize'>{user.role}</p>
          </div>
          {supplier && (
            <div>
              <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Headquarters</p>
              <p className='mt-1 text-lg font-semibold text-neutral-900'>
                {supplier.headquarters || 'Not set'}
              </p>
            </div>
          )}
        </div>
      </SectionCard>

      <SectionCard
        title='Supplier Profile'
      >
        {isLoadingSupplier ? (
          <div className='text-sm text-neutral-500'>Loading supplier profile...</div>
        ) : supplier ? (
          <div className='grid gap-4 md:grid-cols-2'>
            <div>
              <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Legal Entity</p>
              <p className='mt-1 text-lg font-semibold text-neutral-900'>
                {supplier.legal_entity || supplier.name}
              </p>
            </div>
            <div>
              <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Primary Contact</p>
              <p className='mt-1 text-lg font-semibold text-neutral-900'>{user.email}</p>
            </div>
            <div>
              <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Registered Address</p>
              <p className='mt-1 text-lg font-semibold text-neutral-900'>
                {supplier.registered_address || supplier.address || 'Not set'}
              </p>
            </div>
            <div>
              <p className='text-xs uppercase tracking-[0.25em] text-neutral-400'>Banking Currency</p>
              <p className='mt-1 text-lg font-semibold text-neutral-900'>
                {supplier.banking_currency || 'Not set'}
              </p>
            </div>
          </div>
        ) : (
          <div className='text-sm text-neutral-500'>
            Supplier profile could not be loaded. Please try again later.
          </div>
        )}
      </SectionCard>

      <SectionCard
        title='Sign out'
        description='Log out from the owner workspace. You can sign back in at any time with your credentials.'
        action={(
          <Button
            type='button'
            onClick={handleSignOut}
            className='rounded-lg border border-rose-300 px-4 py-2 text-sm font-medium text-rose-600 transition hover:bg-rose-50'
          >
            Log out
          </Button>
        )}
      >
      </SectionCard>
    </div>
  )
}

