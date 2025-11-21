import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Allow public paths
  if (pathname === '/' || pathname.startsWith('/_next') || pathname.startsWith('/api')) {
    return NextResponse.next()
  }

  // Allow login and signup pages - actual auth check happens in the page component
  if (pathname.startsWith('/login') || pathname.startsWith('/signup')) {
    return NextResponse.next()
  }

  // For protected routes, we'll check auth in the page/layout components
  // since JWT token is stored in localStorage (client-side only)
  // This middleware just ensures the route exists and handles redirects
  if (pathname.startsWith('/owner') || pathname.startsWith('/manager') || pathname.startsWith('/sales')) {
    return NextResponse.next()
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/owner/:path*', '/manager/:path*', '/sales/:path*', '/login', '/signup']
}


