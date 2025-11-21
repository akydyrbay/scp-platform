'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import toast from 'react-hot-toast'

import { PageHeader } from '@/components/ui/page-header'
import { getProducts, deleteProduct, updateProduct, type Product } from '@/lib/api/products'

const presetCategories = ['All', 'Fresh Fruit', 'Meat', 'Dairy', 'Bakery', 'Seasonal', 'Organic'] as const

type CategoryFilter = (typeof presetCategories)[number]

const saleFilters = ['On Sale', 'Draft'] as const

type ProductStatus = (typeof saleFilters)[number]

type CatalogProduct = {
  id: string
  sku: string
  name: string
  category: string
  price: string
  originalPrice?: string
  discount?: number
  sold?: string
  status: ProductStatus
  image: string
}

// Extract category from description (only if description contains category format)
// This is a fallback - should prefer product.category from database
function extractCategory(description: string | null | undefined): string {
  if (!description) return 'Uncategorized'

  // Try [Category] format first
  const bracketMatch = description.match(/^\[([^\]]+)\]\s*(.*)$/)
  if (bracketMatch) {
    return bracketMatch[1].trim()
  }

  // Try Category: format
  const colonMatch = description.match(/^([^:]+):\s*(.*)$/)
  if (colonMatch) {
    return colonMatch[1].trim()
  }

  // If no category format found, return 'Uncategorized' instead of the whole description
  return 'Uncategorized'
}

// Map backend product to UI product
function mapProductToUI(product: Product): CatalogProduct {
  const discount = product.discount || 0
  const finalPrice = discount > 0 ? product.price * (1 - discount / 100) : product.price
  
  // Determine status based on stock level only
  // Draft: stock_level = 0, On Sale: stock_level > 0
  const status: ProductStatus = product.stock_level > 0 ? 'On Sale' : 'Draft'

  // Always prefer backend category field from database
  // Only use description extraction as last resort if category is truly missing
  let category: string
  if (product.category && product.category.trim()) {
    category = product.category.trim()
  } else {
    // Fallback to description extraction only if category is missing
    category = extractCategory(product.description)
    // Debug: log when falling back to description extraction
    console.warn(`[Catalog] Product "${product.name}" has no category field. Using fallback:`, {
      productCategory: product.category,
      extractedCategory: category,
      description: product.description
    })
  }
  
  // Debug log for category mapping
  if (product.name && product.category) {
    console.log(`[Catalog] Product "${product.name}" category mapping:`, {
      dbCategory: product.category,
      mappedCategory: category
    })
  }

  // Generate SKU from product ID: take first 8 characters (without dashes) and convert to uppercase
  // Example: a1111111-1111-1111-1111-111111111111 -> SKU-A1111111
  const skuFromId = product.id.replace(/-/g, '').substring(0, 8).toUpperCase()
  
  // Format prices
  const priceStr = `₸ ${finalPrice.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} / ${product.unit}`
  const originalPriceStr = discount > 0 
    ? `₸ ${product.price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} / ${product.unit}`
    : undefined
  
  return {
    id: product.id,
    sku: `SKU-${skuFromId}`,
    name: product.name,
    category,
    price: priceStr,
    originalPrice: originalPriceStr,
    discount: discount > 0 ? discount : undefined,
    status,
    image: product.image_url || ''
  }
}

export default function ManagerCatalogPage() {
  const [activeStatus, setActiveStatus] = useState<ProductStatus>('On Sale')
  const [activeCategory, setActiveCategory] = useState<CategoryFilter>('All')
  const [products, setProducts] = useState<Product[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        setIsLoading(true)
        const data = await getProducts(1, 100)
        const productsList = Array.isArray(data.results) ? data.results : []
        console.log('[Catalog] Fetched products:', {
          total: productsList.length,
          rawData: data,
          hasResults: 'results' in data,
          resultsType: typeof data.results,
          resultsIsArray: Array.isArray(data.results),
          sample: productsList.slice(0, 3).map(p => ({
            name: p.name,
            category: p.category,
            stock_level: p.stock_level,
            hasCategory: !!p.category
          }))
        })
        
        if (productsList.length === 0) {
          console.warn('[Catalog] No products found!', {
            dataKeys: Object.keys(data),
            dataResults: data.results,
            dataType: typeof data.results
          })
        }
        
        setProducts(productsList)
      } catch (error) {
        console.error('Failed to fetch products:', error)

        setProducts([])
        toast.error('Failed to load products')
      } finally {
        setIsLoading(false)
      }
    }

    fetchProducts()
  }, [])

  const filterStyles: Record<ProductStatus, string> = {
    'On Sale': 'border-emerald-200 bg-emerald-50 text-emerald-600 shadow-[0_12px_24px_rgba(16,185,129,0.18)]',
    Draft: 'border-neutral-300 bg-neutral-100 text-neutral-600 shadow-[0_12px_24px_rgba(148,163,184,0.18)]'
  }

  const statusStyles: Record<ProductStatus, string> = {
    'On Sale': 'border-emerald-200 bg-emerald-50 text-emerald-600',
    Draft: 'border-neutral-300 bg-neutral-100 text-neutral-600'
  }

  const uiProducts = useMemo(() => {
    if (!products || !Array.isArray(products)) {
      console.log('[Catalog] No products or products is not an array:', products)
      return []
    }
    const mapped = products.map(mapProductToUI)
    console.log('[Catalog] Mapped products:', {
      total: mapped.length,
      categories: [...new Set(mapped.map(p => p.category))],
      statuses: [...new Set(mapped.map(p => p.status))],
      sample: mapped.slice(0, 3).map(p => ({ name: p.name, category: p.category, status: p.status }))
    })
    return mapped
  }, [products])

  const displayedProducts = useMemo(() => {
    console.log('[Catalog] Filtering products:', {
      totalProducts: uiProducts.length,
      activeStatus,
      activeCategory,
      productsByStatus: {
        'On Sale': uiProducts.filter(p => p.status === 'On Sale').length,
        'Draft': uiProducts.filter(p => p.status === 'Draft').length
      }
    })
    
    // Filter by status
    let filtered = uiProducts.filter(product => product.status === activeStatus)
    console.log('[Catalog] After status filter:', filtered.length)

    // Then filter by category if not 'All'
    if (activeCategory !== 'All') {
      filtered = filtered.filter(product => {
        const matches = product.category === activeCategory
        if (!matches) {
          console.log('[Catalog] Category mismatch:', {
            productCategory: product.category,
            activeCategory,
            productName: product.name
          })
        }
        return matches
      })
      console.log('[Catalog] After category filter:', filtered.length)
    }

    return filtered
  }, [uiProducts, activeStatus, activeCategory])

  const handleDelete = async (id: string, productName: string) => {
    if (!confirm(`Are you sure you want to delete "${productName}"? This action cannot be undone.`)) return

    try {
      await deleteProduct(id)
      // Refresh products list instead of just filtering to ensure data consistency
      const data = await getProducts(1, 100)
      setProducts(Array.isArray(data.results) ? data.results : [])
      toast.success('Product deleted successfully')
    } catch (error: any) {
      console.error('Failed to delete product:', error)
      const message = error.message || error.response?.data?.error?.message || 'Failed to delete product'
      toast.error(message)
    }
  }

  const handleDiscontinue = async (id: string) => {
    try {
      const product = products.find(p => p.id === id)
      if (!product) return

      // Discontinue: Set stock_level to 0 to change from "On Sale" to "Draft"
      await updateProduct(id, {
        stock_level: 0
      })

      // Refresh products list
      const data = await getProducts(1, 100)
      setProducts(Array.isArray(data.results) ? data.results : [])

      toast.success('Product discontinued successfully! Status: Draft')
    } catch (error: any) {
      console.error('Failed to discontinue product:', error)
      const message = error.response?.data?.error?.message || 'Failed to discontinue product'
      toast.error(message)
    }
  }

  const handlePublish = async (id: string) => {
    try {
      const product = products.find(p => p.id === id)
      if (!product) return

      // Publish sets stock_level > 0 to make it "On Sale"
      const newStockLevel = product.stock_level > 0 ? product.stock_level : 1

      await updateProduct(id, {
        stock_level: newStockLevel
      })

      // Refresh products list
      const data = await getProducts(1, 100)
      setProducts(Array.isArray(data.results) ? data.results : [])

      toast.success('Product published successfully! Status: On Sale')
    } catch (error: any) {
      console.error('Failed to publish product:', error)
      const message = error.response?.data?.error?.message || 'Failed to publish product'
      toast.error(message)
    }
  }

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Catalog Management'
        description='Maintain product data, pricing, and merchandising details across the supplier catalog.'
      />

      <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
        <div className='space-y-4'>
          <div className='flex flex-wrap items-center justify-between gap-4'>
            <h3 className='text-sm font-semibold text-neutral-700'>All Products</h3>
            <span className='rounded-full bg-neutral-100 px-3 py-1 text-xs font-medium text-neutral-500'>
              {uiProducts.length} total
            </span>
          </div>
          <div className='flex flex-wrap items-center gap-3'>
            {presetCategories.map(category => (
              <button
                key={category}
                onClick={() => setActiveCategory(category)}
                className={`rounded-full border px-4 py-2 text-sm font-semibold transition whitespace-nowrap ${activeCategory === category
                    ? 'border-primary-200 bg-primary-100 text-primary-700 shadow-[0_12px_24px_rgba(59,130,246,0.12)]'
                    : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-200 hover:text-primary-500'
                  }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className='rounded-2xl border border-neutral-200 bg-white p-6 shadow-[0_20px_48px_rgba(15,23,42,0.06)]'>
        <div className='flex flex-wrap items-center justify-between gap-4'>
          <div className='flex flex-wrap gap-3'>
            {saleFilters.map(filter => (
              <button
                key={filter}
                onClick={() => setActiveStatus(filter)}
                className={`rounded-xl border px-6 py-2 text-sm font-semibold transition whitespace-nowrap ${activeStatus === filter
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
            <div key={product.sku} className='flex gap-6 rounded-2xl border border-neutral-100 bg-white p-5 shadow-sm shadow-neutral-200/40'>
              <div className='h-32 w-48 overflow-hidden rounded-2xl border border-neutral-200 bg-neutral-100'>
                {product.image ? (
                  <img
                    src={product.image}
                    alt={product.name}
                    className='h-full w-full object-cover'
                  />
                ) : (
                  <div className='flex h-full w-full items-center justify-center bg-neutral-50 text-xs text-neutral-400'>
                    No Image
                  </div>
                )}
              </div>
              <div className='flex flex-1 flex-col gap-4'>
                <div className='flex items-start justify-between gap-4'>
                  <div>
                    <p className='text-xs uppercase tracking-[0.35em] text-neutral-400'>{product.sku}</p>
                    <h3 className='mt-2 text-lg font-semibold text-neutral-900'>{product.name}</h3>
                    <p className='text-sm text-neutral-500'>{product.category}</p>
                  </div>
                  <span className={`rounded-full border px-3 py-1 text-xs font-semibold ${statusStyles[product.status]}`}>
                    {product.status}
                  </span>
                </div>

                <div className='flex flex-wrap items-center gap-4 text-sm'>
                  {product.discount && product.originalPrice ? (
                    // Show original price with strikethrough and discounted price in red
                    <div className='flex flex-col gap-1'>
                      <span className='text-neutral-400 line-through text-xs'>{product.originalPrice}</span>
                      <span className='font-semibold text-rose-600 text-base'>{product.price}</span>
                      <span className='text-xs font-semibold text-rose-600'>{product.discount}% OFF</span>
                    </div>
                  ) : (
                    // Show regular price
                    <span className='font-semibold text-neutral-900'>{product.price}</span>
                  )}
                  {product.status === 'On Sale' && product.sold ? <span className='text-neutral-600'>{product.sold}</span> : null}
                </div>

                <div className='mt-auto space-y-2'>
                  <div className={`grid gap-3 text-sm font-semibold ${product.status === 'On Sale' ? 'grid-cols-1' : 'grid-cols-2'}`}>
                    {product.status === 'On Sale' ? (
                      // On Sale: Only Discontinue button (no Edit Listing)
                      <button
                        onClick={() => handleDiscontinue(product.id)}
                        className='rounded-xl bg-rose-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_10px_20px_rgba(239,68,68,0.25)] transition hover:bg-rose-600'>
                        Discontinue
                      </button>
                    ) : (
                      // To Be On Sale or Draft: Edit Listing and Publish buttons
                      <>
                        <Link
                          href={`/manager/catalog/${product.id}/edit`}
                          className='rounded-xl border border-neutral-200 px-3 py-2 text-center text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'
                        >
                          Edit Listing
                        </Link>
                        <button
                          onClick={() => handlePublish(product.id)}
                          className='rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-[0_12px_24px_rgba(16,185,129,0.25)] transition hover:bg-emerald-600'>
                          Publish
                        </button>
                      </>
                    )}
                  </div>
                  <button
                    onClick={() => handleDelete(product.id, product.name)}
                    className='w-full rounded-xl border border-neutral-200 px-3 py-2 text-center text-sm font-semibold text-neutral-600 transition hover:border-rose-300 hover:bg-rose-50 hover:text-rose-600'
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

