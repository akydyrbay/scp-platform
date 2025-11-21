import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Allow public paths
  if (pathname === '/' || pathname.startsWith('/_next') || pathname.startsWith('/api')) {
    return NextResponse.next()
  }

  // Allow login and signup pages
  if (pathname.startsWith('/login') || pathname.startsWith('/signup')) {
    return NextResponse.next()
  }

  // Check for authentication cookie on protected routes
  if (pathname.startsWith('/owner') || pathname.startsWith('/manager') || pathname.startsWith('/sales')) {
    const authToken = request.cookies.get('auth_token')
    
    // If no auth token cookie exists, redirect to login
    if (!authToken || !authToken.value) {
      const loginUrl = new URL('/login', request.url)
      // Add redirect parameter so user can return after login
      loginUrl.searchParams.set('redirect', pathname)
      return NextResponse.redirect(loginUrl)
    }
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/owner/:path*', '/manager/:path*', '/sales/:path*', '/login', '/signup']
}


