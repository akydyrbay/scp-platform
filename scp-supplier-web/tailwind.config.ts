import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './constants/**/*.{ts,tsx}',
    './lib/**/*.{ts,tsx}'
  ],
  theme: {
    extend: {
      colors: {
        neutral: {
          50: '#F9FAFB',
          100: '#F3F4F6',
          200: '#E5E7EB',
          300: '#CBD5F5',
          500: '#6B7280',
          700: '#1F2937',
          900: '#111827'
        },
        primary: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          500: '#3B82F6',
          600: '#2563EB',
          700: '#1E40AF',
          900: '#0B1B4B'
        },
        secondary: {
          50: '#F5F7FB',
          100: '#EAEFFC',
          500: '#1D4ED8',
          700: '#1E1B4B',
          900: '#101228'
        },
        success: '#10B981',
        warning: '#F59E0B',
        danger: '#EF4444'
      },
      boxShadow: {
        card: '0px 24px 48px rgba(15, 23, 42, 0.08)'
      },
      borderRadius: {
        xl: '1rem',
        '2xl': '1.5rem'
      },
      fontFamily: {
        sans: ['var(--font-geist-sans)', 'Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif']
      }
    }
  },
  plugins: []
}

export default config

