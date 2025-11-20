'use client'

import { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import toast from 'react-hot-toast'
import * as z from 'zod'

import { login } from '@/lib/api/auth'
import { useAuthStore } from '@/lib/store/auth-store'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const loginSchema = z.object({
  email: z.string().min(1, 'Email is required').email('Invalid email address'),
  password: z.string()
    .min(1, 'Password is required')
    .refine((val) => val.length >= 6, 'Password must be at least 6 characters')
})

type LoginFormValues = z.infer<typeof loginSchema>

function resolveRoleDestination (role: string): string {
  if (role === 'owner') return '/owner/dashboard'
  if (role === 'manager') return '/manager/dashboard'
  if (role === 'sales_rep' || role === 'sales') return '/sales/dashboard'
  return '/dashboard'
}

export default function LoginPage () {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { setUser } = useAuthStore()
  const [isLoading, setIsLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors }
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    mode: 'onSubmit',
    defaultValues: {
      email: '',
      password: ''
    }
  })

  const onSubmit = async (data: LoginFormValues) => {
    setIsLoading(true)
    try {
      const response = await login({
        email: data.email,
        password: data.password
      })

      setUser(response.user)
      toast.success('Login successful!')
      
      const redirect = searchParams.get('redirect')
      const destination = redirect && redirect.startsWith('/')
        ? redirect
        : resolveRoleDestination(response.user.role)
      
      router.push(destination)
    } catch (error: any) {
      // Backend returns errors in format: { success: false, error: { code: "ERROR", message: "..." } }
      const message = error.response?.data?.error?.message || error.response?.data?.message || error.message || 'Login failed. Please check your credentials.'
      toast.error(message)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className='flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-50 via-white to-neutral-100 p-4'>
      <Card className='w-full max-w-md rounded-3xl border border-neutral-200 px-6 py-8 shadow-[0_30px_80px_rgba(59,130,246,0.15)]'>
        <CardHeader className='space-y-3 text-center'>
          <CardTitle className='text-2xl font-bold text-neutral-900'>SCP Supplier Portal</CardTitle>
          <CardDescription className='text-neutral-500'>Sign in to your account to continue</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className='space-y-5'>
            <div className='space-y-2'>
              <Label htmlFor='email'>Email</Label>
              <Input
                id='email'
                type='email'
                placeholder='name@example.com'
                autoComplete='email'
                {...register('email')}
                disabled={isLoading}
              />
              {errors.email && (
                <p className='text-sm text-danger'>{errors.email.message}</p>
              )}
            </div>
            <div className='space-y-2'>
              <Label htmlFor='password'>Password</Label>
              <Input
                id='password'
                type='password'
                autoComplete='current-password'
                {...register('password')}
                disabled={isLoading}
              />
              {errors.password && (
                <p className='text-sm text-danger'>{errors.password.message}</p>
              )}
            </div>
            <Button type='submit' disabled={isLoading} className='w-full'>
              {isLoading ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}

