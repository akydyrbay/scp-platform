'use client'

import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/store/auth-store'
import { logout } from '@/lib/api/auth'
import { PageHeader } from '@/components/ui/page-header'
import { SectionCard } from '@/components/ui/section-card'
import { Button } from '@/components/ui/button'
import toast from 'react-hot-toast'

export default function ManagerSettingsPage() {
  const router = useRouter()
  const { user } = useAuthStore()

  const handleSignOut = async () => {
    try {
      const { setUser } = useAuthStore.getState()
      // Clear user from store first
      setUser(null)
      // Then logout (which clears tokens)
      await logout()
      toast.success('Logged out successfully')
      // Use replace instead of push to avoid back button issues and prevent loops
      router.replace('/login')
      // Force a small delay to ensure state is cleared before navigation
      setTimeout(() => {
        if (window.location.pathname !== '/login') {
          window.location.replace('/login')
        }
      }, 100)
    } catch (error) {
      console.error('Logout error:', error)
      // Even if logout fails, clear tokens and redirect
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
        description='Manage your profile details and preferences for the managerial workspace.'
      />

      <SectionCard
        title='Personal Information'
        description='Details visible to other internal stakeholders.'
        action={(
          <Button
            variant='secondary'
            onClick={() => toast.success('Edit profile feature coming soon')}
            className='rounded-lg border border-neutral-200 px-4 py-2 text-sm font-medium text-primary-500 transition hover:bg-primary-50 hover:text-primary-600'
          >
            Edit Information
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
        </div>
      </SectionCard>

      <SectionCard
        title='Sign out'
        description='Log out from the managerial workspace. You can sign back in at any time with your credentials.'
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

