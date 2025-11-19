import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

type UserRole = 'owner' | 'manager' | 'sales_rep' | 'sales'

const roleRoutes: Record<UserRole, RegExp> = {
  owner: /^\/owner(\/|$)/,
  manager: /^\/manager(\/|$)/,
  sales_rep: /^\/sales(\/|$)/,
  sales: /^\/sales(\/|$)/
}

const dashboardByRole: Record<UserRole, string> = {
  owner: '/owner/dashboard',
  manager: '/manager/dashboard',
  sales_rep: '/sales/dashboard',
  sales: '/sales/dashboard'
}

function parseJWT (token: string): { role?: UserRole; exp?: number } | null {
  try {
    const base64Url = token.split('.')[1]
    if (!base64Url) return null
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const jsonPayload = decodeURIComponent(
      Buffer.from(base64, 'base64')
        .toString()
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    )
    return JSON.parse(jsonPayload) as { role?: UserRole; exp?: number }
  } catch {
    return null
  }
}

function getRoleFromToken (token: string): UserRole | null {
  const payload = parseJWT(token)
  if (!payload?.role) return null
  
  // Map backend roles to frontend roles
  if (payload.role === 'sales_rep') {
    return 'sales'
  }
  
  if (['owner', 'manager'].includes(payload.role)) {
    return payload.role as UserRole
  }
  
  return null
}

export function middleware (request: NextRequest) {
  const { pathname } = request.nextUrl

  // Skip Next.js internal routes and static files
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname === '/favicon.ico' ||
    pathname.startsWith('/images') ||
    pathname.startsWith('/public')
  ) {
    return NextResponse.next()
  }

  const token = request.cookies.get('auth_token')?.value ||
    (request.headers.get('authorization')?.replace('Bearer ', '') || null)

  // Handle login page
  if (pathname === '/login' || pathname.startsWith('/login')) {
    if (!token) return NextResponse.next()
    
    const role = getRoleFromToken(token)
    if (!role) return NextResponse.next()
    
    return NextResponse.redirect(new URL(dashboardByRole[role], request.url))
  }

  // Check if route requires authentication
  const requiresAuth = 
    pathname.startsWith('/owner') ||
    pathname.startsWith('/manager') ||
    pathname.startsWith('/sales') ||
    pathname.startsWith('/dashboard') ||
    pathname.startsWith('/catalog') ||
    pathname.startsWith('/orders') ||
    pathname.startsWith('/consumers') ||
    pathname.startsWith('/incidents') ||
    pathname.startsWith('/users')

  if (requiresAuth && !token) {
    const url = new URL('/login', request.url)
    url.searchParams.set('redirect', pathname)
    return NextResponse.redirect(url)
  }

  if (!requiresAuth) {
    return NextResponse.next()
  }

  const role = token ? getRoleFromToken(token) : null

  if (!role) {
    const url = new URL('/login', request.url)
    url.searchParams.set('redirect', pathname)
    return NextResponse.redirect(url)
  }

  // Check role-based route access
  if (pathname.startsWith('/owner') && role !== 'owner') {
    return NextResponse.redirect(new URL(dashboardByRole[role], request.url))
  }

  if (pathname.startsWith('/manager') && role !== 'manager') {
    return NextResponse.redirect(new URL(dashboardByRole[role], request.url))
  }
  
  if (pathname.startsWith('/sales') && role !== 'sales' && role !== 'sales_rep') {
    return NextResponse.redirect(new URL(dashboardByRole[role], request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
