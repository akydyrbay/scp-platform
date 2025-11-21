'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import toast from 'react-hot-toast'
import Link from 'next/link'
import * as z from 'zod'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const signupSchema = z.object({
  // Company information
  company_name: z.string().min(1, 'Company name is required'),
  description: z.string().optional(),
  phone_number: z.string().optional(),
  address: z.string().optional(),

  // Owner information 
  owner_email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  confirm_password: z.string().min(8, 'Please confirm your password'),
  owner_first_name: z.string().min(1, 'First name is required'),
  owner_last_name: z.string().min(1, 'Last name is required'),
}).refine((data) => data.password === data.confirm_password, {
  message: "Passwords don't match",
  path: ['confirm_password'],
})

type SignupFormValues = z.infer<typeof signupSchema>

export default function SignupPage() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors }
  } = useForm<SignupFormValues>({
    resolver: zodResolver(signupSchema)
  })

  const onSubmit = async (data: SignupFormValues) => {
    setIsLoading(true)
    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000/api/v1'

      const response = await fetch(`${API_BASE_URL}/supplier/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          company_name: data.company_name,
          company_email: data.owner_email, // Use owner email as company email
          description: data.description || undefined,
          phone_number: data.phone_number || undefined,
          address: data.address || undefined,
          owner_email: data.owner_email,
          password: data.password,
          owner_first_name: data.owner_first_name,
          owner_last_name: data.owner_last_name,
        })
      })

      const result = await response.json()

      if (!response.ok) {
        const message = result.error?.message || 'Registration failed'
        throw new Error(message)
      }

      toast.success('Registration successful! You can now log in.')
      router.push('/login')
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Registration failed. Please try again.'
      toast.error(message)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className='flex min-h-screen items-center justify-center bg-gradient-to-br from-primary-50 via-white to-neutral-100 p-4'>
      <Card className='w-full max-w-2xl rounded-3xl border border-neutral-200 px-6 py-8 shadow-[0_30px_80px_rgba(59,130,246,0.15)]'>
        <CardHeader className='space-y-3 text-center'>
          <CardTitle className='text-2xl font-bold text-neutral-900'>Register as Supplier Owner</CardTitle>
          <CardDescription className='text-neutral-500'>
            Create your company account. Your email will be used as the company contact email. As the owner, you can manage managers and sales representatives.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className='space-y-6'>
            {/* Company Information Section */}
            <div className='space-y-4 rounded-xl border border-neutral-200 bg-neutral-50 p-4'>
              <h3 className='text-lg font-semibold text-neutral-900'>Company Information</h3>

              <div className='space-y-2'>
                <Label htmlFor='company_name'>Company Name *</Label>
                <Input
                  id='company_name'
                  {...register('company_name')}
                  disabled={isLoading}
                  placeholder='Your Company Name'
                />
                {errors.company_name && (
                  <p className='text-sm text-rose-500'>{errors.company_name.message}</p>
                )}
              </div>

              <div className='grid gap-4 md:grid-cols-2'>
                <div className='space-y-2'>
                  <Label htmlFor='phone_number'>Phone Number</Label>
                  <Input
                    id='phone_number'
                    {...register('phone_number')}
                    disabled={isLoading}
                    placeholder='+77001234567'
                  />
                  {errors.phone_number && (
                    <p className='text-sm text-rose-500'>{errors.phone_number.message}</p>
                  )}
                </div>

                <div className='space-y-2'>
                  <Label htmlFor='address'>Address</Label>
                  <Input
                    id='address'
                    {...register('address')}
                    disabled={isLoading}
                    placeholder='Company Address'
                  />
                  {errors.address && (
                    <p className='text-sm text-rose-500'>{errors.address.message}</p>
                  )}
                </div>
              </div>

              <div className='space-y-2'>
                <Label htmlFor='description'>Description</Label>
                <textarea
                  id='description'
                  {...register('description')}
                  disabled={isLoading}
                  placeholder='Brief description of your company'
                  className='h-20 w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm text-neutral-700 shadow-sm transition focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-100'
                />
                {errors.description && (
                  <p className='text-sm text-rose-500'>{errors.description.message}</p>
                )}
              </div>
            </div>

            {/* Owner Information Section */}
            <div className='space-y-4 rounded-xl border border-neutral-200 bg-neutral-50 p-4'>
              <h3 className='text-lg font-semibold text-neutral-900'>Owner Account Information</h3>

              <div className='grid gap-4 md:grid-cols-2'>
                <div className='space-y-2'>
                  <Label htmlFor='owner_first_name'>First Name *</Label>
                  <Input
                    id='owner_first_name'
                    {...register('owner_first_name')}
                    disabled={isLoading}
                    placeholder='John'
                  />
                  {errors.owner_first_name && (
                    <p className='text-sm text-rose-500'>{errors.owner_first_name.message}</p>
                  )}
                </div>

                <div className='space-y-2'>
                  <Label htmlFor='owner_last_name'>Last Name *</Label>
                  <Input
                    id='owner_last_name'
                    {...register('owner_last_name')}
                    disabled={isLoading}
                    placeholder='Doe'
                  />
                  {errors.owner_last_name && (
                    <p className='text-sm text-rose-500'>{errors.owner_last_name.message}</p>
                  )}
                </div>
              </div>

              <div className='space-y-2'>
                <Label htmlFor='owner_email'>Owner Email *</Label>
                <Input
                  id='owner_email'
                  type='email'
                  {...register('owner_email')}
                  disabled={isLoading}
                  placeholder='owner@example.com'
                />
                {errors.owner_email && (
                  <p className='text-sm text-rose-500'>{errors.owner_email.message}</p>
                )}
                <p className='text-xs text-neutral-500'>
                  This will be your login email and also used as your company contact email
                </p>
              </div>

              <div className='grid gap-4 md:grid-cols-2'>
                <div className='space-y-2'>
                  <Label htmlFor='password'>Password *</Label>
                  <Input
                    id='password'
                    type='password'
                    {...register('password')}
                    disabled={isLoading}
                    placeholder='Minimum 8 characters'
                  />
                  {errors.password && (
                    <p className='text-sm text-rose-500'>{errors.password.message}</p>
                  )}
                </div>

                <div className='space-y-2'>
                  <Label htmlFor='confirm_password'>Confirm Password *</Label>
                  <Input
                    id='confirm_password'
                    type='password'
                    {...register('confirm_password')}
                    disabled={isLoading}
                    placeholder='Confirm password'
                  />
                  {errors.confirm_password && (
                    <p className='text-sm text-rose-500'>{errors.confirm_password.message}</p>
                  )}
                </div>
              </div>
            </div>

            <Button type='submit' disabled={isLoading} className='w-full'>
              {isLoading ? 'Creating Account...' : 'Create Account'}
            </Button>

            <p className='text-center text-sm text-neutral-500'>
              Already have an account?{' '}
              <Link href='/login' className='font-semibold text-primary-500 hover:text-primary-600'>
                Sign in
              </Link>
            </p>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}

