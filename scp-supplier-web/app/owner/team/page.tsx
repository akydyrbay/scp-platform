'use client'

import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import toast from 'react-hot-toast'
import * as z from 'zod'

import { PageHeader } from '@/components/ui/page-header'
import { Dialog } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getUsers, createUser, deleteUser, type User } from '@/lib/api/users'

const createUserSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  first_name: z.string().min(1, 'First name is required'),
  last_name: z.string().min(1, 'Last name is required'),
  role: z.enum(['manager', 'sales_rep'], {
    required_error: 'Please select a role'
  })
})

type CreateUserFormValues = z.infer<typeof createUserSchema>

type MemberStatus = 'active' | 'suspended' | 'inactive'

const statusStyles: Record<MemberStatus, string> = {
  active: 'bg-emerald-100/70 border border-emerald-200 text-emerald-700 shadow-inner shadow-emerald-200/40 backdrop-blur-lg',
  suspended: 'bg-amber-100/60 border border-amber-200 text-amber-700 shadow-inner shadow-amber-200/40 backdrop-blur-lg',
  inactive: 'bg-neutral-200/60 border border-neutral-300 text-neutral-600 shadow-inner shadow-neutral-300/40 backdrop-blur-lg'
}

function renderStatus(status: MemberStatus) {
  return (
    <span className={`inline-flex items-center justify-center rounded-2xl px-4 py-1.5 text-sm font-semibold capitalize ${statusStyles[status]}`}>
      {status}
    </span>
  )
}


function mapRole(role: string): string {
  const roleMap: Record<string, string> = {
    owner: 'Owner',
    manager: 'Manager',
    sales_rep: 'Sales Representative'
  }
  return roleMap[role] || role
}

export default function OwnerTeamPage() {
  const [users, setUsers] = useState<User[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isCreating, setIsCreating] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset
  } = useForm<CreateUserFormValues>({
    resolver: zodResolver(createUserSchema)
  })

  useEffect(() => {
    fetchUsers()
  }, [])

  const fetchUsers = async () => {
    try {
      setIsLoading(true)
      console.log('Fetching users in team page...')
      const data = await getUsers()
      console.log('Users fetched:', data)
      console.log('Number of users:', data.length)


      if (Array.isArray(data)) {
        setUsers(data)
        if (data.length === 0) {
          console.warn('No users returned from API')
        }
      } else {
        console.error('Received non-array data:', data)
        setUsers([])
      }
    } catch (error) {
      console.error('Failed to fetch users:', error)
      toast.error('Failed to load team members')
      setUsers([])
    } finally {
      setIsLoading(false)
    }
  }

  const onSubmit = async (data: CreateUserFormValues) => {
    try {
      setIsCreating(true)
      console.log('Creating user with data:', data)

      const newUser = await createUser({
        ...data,
        role: data.role as 'manager' | 'sales_rep'
      })

      console.log('User created successfully:', newUser)


      if (newUser && newUser.id) {
        setUsers(prevUsers => {
          const exists = prevUsers.some(u => u.id === newUser.id)
          if (exists) {
            console.log('User already in list, refreshing from server...')
            fetchUsers()
            return prevUsers
          }

          return [newUser, ...prevUsers]
        })
      }


      await fetchUsers()

      toast.success('Team member created successfully!')
      setIsDialogOpen(false)
      reset()
    } catch (error: any) {
      console.error('Failed to create user:', {
        message: error.message,
        status: error.response?.status,
        data: error.response?.data,
        fullError: error
      })


      const message = error.message || error.response?.data?.error?.message || 'Failed to create team member'
      toast.error(message)
    } finally {
      setIsCreating(false)
    }
  }

  const handleDelete = async (id: string, email: string) => {
    if (!confirm(`Are you sure you want to delete ${email}?`)) return

    try {
      await deleteUser(id) // Refresh the entire list instead of filtering
      await fetchUsers()
      toast.success('Team member deleted successfully')
    } catch (error) {
      console.error('Failed to delete user:', error)
      toast.error('Failed to delete team member')
    }
  }

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Team Management'
        description='Create and manage managers and sales representatives. New users can log in immediately with their email and password.'
        cta={(
          <button
            onClick={() => setIsDialogOpen(true)}
            className='rounded-xl bg-[#4f46e5] px-5 py-3 text-sm font-semibold text-white shadow-[0px_14px_30px_rgba(79,70,229,0.28)] transition hover:bg-[#4338ca]'
          >
            Add Team Member
          </button>
        )}
      />

      <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
        <header className='mb-6'>
          <h2 className='text-xl font-semibold text-neutral-900'>Team Directory</h2>
          <p className='mt-1 text-sm text-neutral-500'>Overview of team members, roles, statuses.</p>
        </header>

        {isLoading ? (
          <div className='py-10 text-center text-neutral-500'>Loading team members...</div>
        ) : users.length === 0 ? (
          <div className='py-10 text-center text-neutral-500'>No team members yet. Add your first team member to get started.</div>
        ) : (
          <div className='overflow-hidden rounded-2xl border border-neutral-100'>
            <table className='min-w-full divide-y divide-neutral-100 text-left'>
              <thead className='bg-neutral-50 text-xs uppercase tracking-[0.3em] text-neutral-500'>
                <tr>
                  <th className='px-6 py-4'>Name</th>
                  <th className='px-6 py-4'>Email</th>
                  <th className='px-6 py-4'>Role</th>
                  <th className='px-6 py-4'>Status</th>
                  <th className='px-6 py-4'>Actions</th>
                </tr>
              </thead>
              <tbody className='divide-y divide-neutral-100 text-sm text-neutral-700'>
                {users.map(user => (
                  <tr key={user.id} className='transition hover:bg-neutral-50'>
                    <td className='px-6 py-4 font-semibold text-neutral-900'>
                      {user.first_name && user.last_name
                        ? `${user.first_name} ${user.last_name}`
                        : user.email}
                    </td>
                    <td className='px-6 py-4'>{user.email}</td>
                    <td className='px-6 py-4'>{mapRole(user.role)}</td>
                    <td className='px-6 py-4'>{renderStatus('active')}</td>
                    <td className='px-6 py-4'>
                      <button
                        onClick={() => handleDelete(user.id, user.email)}
                        className='text-sm text-rose-500 hover:text-rose-600'
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Dialog
        open={isDialogOpen}
        onClose={() => {
          setIsDialogOpen(false)
          reset()
        }}
        title="Add Team Member"
      >
        <form onSubmit={handleSubmit(onSubmit)} className='space-y-5'>
          <div className='space-y-2'>
            <Label htmlFor='first_name'>First Name</Label>
            <Input
              id='first_name'
              {...register('first_name')}
              disabled={isCreating}
            />
            {errors.first_name && (
              <p className='text-sm text-rose-500'>{errors.first_name.message}</p>
            )}
          </div>

          <div className='space-y-2'>
            <Label htmlFor='last_name'>Last Name</Label>
            <Input
              id='last_name'
              {...register('last_name')}
              disabled={isCreating}
            />
            {errors.last_name && (
              <p className='text-sm text-rose-500'>{errors.last_name.message}</p>
            )}
          </div>

          <div className='space-y-2'>
            <Label htmlFor='email'>Email</Label>
            <Input
              id='email'
              type='email'
              {...register('email')}
              disabled={isCreating}
            />
            {errors.email && (
              <p className='text-sm text-rose-500'>{errors.email.message}</p>
            )}
          </div>

          <div className='space-y-2'>
            <Label htmlFor='password'>Password</Label>
            <Input
              id='password'
              type='password'
              {...register('password')}
              disabled={isCreating}
              placeholder='Minimum 8 characters'
            />
            {errors.password && (
              <p className='text-sm text-rose-500'>{errors.password.message}</p>
            )}
            <p className='text-xs text-neutral-500'>The user will use this password to log in.</p>
          </div>

          <div className='space-y-2'>
            <Label htmlFor='role'>Role</Label>
            <select
              id='role'
              {...register('role')}
              disabled={isCreating}
              className='h-10 w-full rounded-xl border border-neutral-200 bg-white px-4 text-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-200'
            >
              <option value=''>Select a role</option>
              <option value='manager'>Manager</option>
              <option value='sales_rep'>Sales Representative</option>
            </select>
            {errors.role && (
              <p className='text-sm text-rose-500'>{errors.role.message}</p>
            )}
          </div>

          <div className='flex gap-3 pt-4'>
            <Button
              type='button'
              variant='secondary'
              onClick={() => {
                setIsDialogOpen(false)
                reset()
              }}
              disabled={isCreating}
              className='flex-1'
            >
              Cancel
            </Button>
            <Button
              type='submit'
              disabled={isCreating}
              className='flex-1'
            >
              {isCreating ? 'Creating...' : 'Create User'}
            </Button>
          </div>
        </form>
      </Dialog>
    </div>
  )
}

