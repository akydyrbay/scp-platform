import { beforeEach, vi } from 'vitest'
import '@testing-library/jest-dom'

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value.toString()
    },
    removeItem: (key: string) => {
      delete store[key]
    },
    clear: () => {
      store = {}
    },
  }
})()

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
})

Object.defineProperty(global, 'localStorage', {
  value: localStorageMock,
})

// Mock window.location
delete (window as any).location
window.location = {
  ...window.location,
  href: 'http://localhost:3000',
  replace: vi.fn(),
  assign: vi.fn(),
} as any

// Mock Next.js router
vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    refresh: vi.fn(),
  }),
  useSearchParams: () => ({
    get: vi.fn(),
  }),
  usePathname: () => '/',
}))

// Mock next/font
vi.mock('next/font/google', () => ({
  Geist: vi.fn(() => ({
    variable: '--font-geist-sans',
    className: 'font-geist-sans',
  })),
  Geist_Mono: vi.fn(() => ({
    variable: '--font-geist-mono',
    className: 'font-geist-mono',
  })),
  Inter: vi.fn(() => ({
    className: 'font-inter',
  })),
}))

beforeEach(() => {
  localStorage.clear()
  vi.clearAllMocks()
})

