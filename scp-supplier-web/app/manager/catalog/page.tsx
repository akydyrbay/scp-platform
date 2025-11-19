'use client'

import { useQuery } from '@tanstack/react-query'
import { useState, useMemo } from 'react'
import Link from 'next/link'
import { getProducts } from '@/lib/api/products'
import { DashboardShell } from '@/components/layout/dashboard-shell'
import { PageHeader } from '@/components/ui/page-header'

export default function ManagerCatalogPage () {
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
  const [activeStatus, setActiveStatus] = useState<'On Sale' | 'To Be On Sale' | 'Draft'>('On Sale')

  const { data: products = [], isLoading } = useQuery({
    queryKey: ['products'],
    queryFn: () => getProducts(token || undefined),
    enabled: !!token,
  })

  const filterStyles: Record<string, string> = {
    'On Sale': 'border-emerald-200 bg-emerald-50 text-emerald-600 shadow-[0_12px_24px_rgba(16,185,129,0.18)]',
    'To Be On Sale': 'border-amber-200 bg-amber-50 text-amber-600 shadow-[0_12px_24px_rgba(251,191,36,0.18)]',
    Draft: 'border-neutral-300 bg-neutral-100 text-neutral-600 shadow-[0_12px_24px_rgba(148,163,184,0.18)]'
  }

  const statusStyles: Record<string, string> = {
    'On Sale': 'border-emerald-200 bg-emerald-50 text-emerald-600',
    'To Be On Sale': 'border-amber-200 bg-amber-50 text-amber-600',
    Draft: 'border-neutral-300 bg-neutral-100 text-neutral-600'
  }

  // Group products by categories (simplified - in real app would come from backend)
  const categories = useMemo(() => {
    const cats = new Set<string>()
    products.forEach(p => {
      // For now, just use a placeholder category
      cats.add('All Products')
    })
    return Array.from(cats)
  }, [products])

  const displayedProducts = useMemo(
    () => products.filter(product => {
      // Map backend status to frontend status (simplified mapping)
      if (activeStatus === 'On Sale') return product.stockLevel > 0
      if (activeStatus === 'Draft') return product.stockLevel === 0
      return false
    }),
    [activeStatus, products]
  )

  if (isLoading) {
    return (
      <DashboardShell role="manager">
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
            <p className="mt-4 text-sm text-neutral-500">Loading catalog...</p>
          </div>
        </div>
      </DashboardShell>
    )
  }

  return (
    <DashboardShell role="manager">
      <div className='space-y-10'>
        <PageHeader
          title='Catalog Management'
          description='Maintain product data, pricing, and merchandising details across the supplier catalog.'
        />

        <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
          <div className='flex flex-wrap items-center justify-between gap-4'>
            <div className='flex flex-wrap items-center gap-3'>
              {categories.map(category => (
                <button
                  key={category}
                  className={`rounded-full border px-4 py-2 text-sm font-semibold transition whitespace-nowrap ${
                    category === 'All Products'
                      ? 'border-primary-100 bg-primary-50 text-primary-600 shadow-[0_12px_24px_rgba(59,130,246,0.12)]'
                      : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-100 hover:text-primary-500'
                  }`}
                >
                  <span className='whitespace-nowrap'>{category}</span>
                  <span className='ml-2 rounded-full bg-neutral-100 px-2 py-0.5 text-xs font-medium text-neutral-500'>
                    {products.length}
                  </span>
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
          <div className='flex flex-wrap items-center justify-between gap-4'>
            <div className='flex flex-wrap gap-3'>
              {(['On Sale', 'To Be On Sale', 'Draft'] as const).map(filter => (
                <button
                  key={filter}
                  onClick={() => setActiveStatus(filter)}
                  className={`rounded-xl border px-6 py-2 text-sm font-semibold transition whitespace-nowrap ${
                    activeStatus === filter
                      ? filterStyles[filter]
                      : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-100 hover:text-primary-500'
                  }`}
                >
                  {filter}
                </button>
              ))}
            </div>
            <Link href='/manager/catalog/create' className='rounded-xl bg-primary-500 px-5 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(59,130,246,0.18)] transition hover:bg-primary-600'>
              Create Product
            </Link>
          </div>

          <div className='mt-6 grid gap-6 lg:grid-cols-2'>
            {displayedProducts.length === 0 ? (
              <div className='col-span-full rounded-2xl border border-dashed border-neutral-200 bg-neutral-50 p-10 text-center text-sm text-neutral-500'>
                No listings in this status yet. Switch filters or create a new product.
              </div>
            ) : null}

            {displayedProducts.map(product => (
              <div key={product.id} className='flex gap-6 rounded-2xl border border-neutral-100 bg-white p-5 shadow-sm shadow-neutral-200/40'>
                <div className='h-32 w-48 overflow-hidden rounded-2xl border border-neutral-200 bg-neutral-100'>
                  {product.imageUrl ? (
                    <img
                      src={product.imageUrl}
                      alt={product.name}
                      className='h-full w-full object-cover'
                    />
                  ) : (
                    <div className='flex h-full w-full items-center justify-center text-neutral-400'>No Image</div>
                  )}
                </div>
                <div className='flex flex-1 flex-col gap-4'>
                  <div className='flex items-start justify-between gap-4'>
                    <div>
                      <p className='text-xs uppercase tracking-[0.35em] text-neutral-400'>{product.id.slice(-8)}</p>
                      <h3 className='mt-2 text-lg font-semibold text-neutral-900'>{product.name}</h3>
                      {product.description && (
                        <p className='text-sm text-neutral-500'>{product.description.slice(0, 50)}</p>
                      )}
                    </div>
                    <span className={`rounded-full border px-3 py-1 text-xs font-semibold ${
                      product.stockLevel > 0 ? statusStyles['On Sale'] : statusStyles['Draft']
                    }`}>
                      {product.stockLevel > 0 ? 'On Sale' : 'Draft'}
                    </span>
                  </div>

                  <div className='flex flex-wrap items-center gap-6 text-sm text-neutral-600'>
                    <span className='font-semibold text-neutral-900'>₸ {product.price.toLocaleString()} / {product.unit}</span>
                    {product.stockLevel > 0 && (
                      <span>Stock: {product.stockLevel} {product.unit}</span>
                    )}
                  </div>

                  <div className='mt-auto grid grid-cols-2 gap-3 text-sm font-semibold'>
                    <button className='rounded-xl border border-neutral-200 px-3 py-2 text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'>Adjust Price</button>
                    <button className='rounded-xl border border-neutral-200 px-3 py-2 text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'>Update Stock</button>
                    <button className='rounded-xl border border-neutral-200 px-3 py-2 text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'>Edit Listing</button>
                    {product.stockLevel > 0 ? (
                      <button className='rounded-xl bg-rose-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_10px_20px_rgba(239,68,68,0.25)] transition hover:bg-rose-600'>
                        Discontinue
                      </button>
                    ) : (
                      <button className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'>
                        Publish
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </DashboardShell>
  )
}

