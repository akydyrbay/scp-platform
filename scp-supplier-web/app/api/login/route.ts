'use server'

import { NextResponse } from 'next/server'
import { verifyCredentials } from '@/lib/auth-credentials'
import { createSession, resolveRoleDestination } from '@/lib/auth'

export async function POST (request: Request) {
  const { email, password } = await request.json() as { email: string, password: string }

  if (!email || !password) {
    return NextResponse.json({ message: 'Missing credentials.' }, { status: 400 })
  }

  const user = verifyCredentials(email, password)
  if (!user) {
    return NextResponse.json({ message: 'Invalid email or password.' }, { status: 401 })
  }

  await createSession(user.role)

  return NextResponse.json({
    user,
    redirect: resolveRoleDestination(user.role)
  })
}

