'use client'

import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import toast from 'react-hot-toast'
import * as z from 'zod'

import { PageHeader } from '@/components/ui/page-header'
import { SectionCard } from '@/components/ui/section-card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { getProduct, updateProduct, type Product } from '@/lib/api/products'
import { uploadFile } from '@/lib/api/upload'

const initialCategories = ['Fresh Fruit', 'Premium Meat', 'Dairy', 'Bakery', 'Seasonal', 'Organic']
const statusOptions = ['On Sale', 'Draft'] as const

type ProductStatus = (typeof statusOptions)[number]

const updateProductSchema = z.object({
  name: z.string().min(1, 'Product name is required'),
  description: z.string().optional(),
  unit: z.string().min(1, 'Unit is required'),
  price: z.number().min(0.01, 'Price must be greater than 0'),
  discount: z.number().min(0).max(100).optional(),
  stock_level: z.number().int().min(0, 'Stock level must be 0 or greater'),
  min_order_quantity: z.number().int().min(1, 'Minimum order quantity must be at least 1'),
})

type UpdateProductFormValues = z.infer<typeof updateProductSchema>

export default function ManagerCatalogEditPage() {
  const router = useRouter()
  const params = useParams<{ id: string }>()
  const productId = params.id

  const [categories] = useState(initialCategories)
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)
  const [newCategory, setNewCategory] = useState('')
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isUploading, setIsUploading] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [currentProduct, setCurrentProduct] = useState<Product | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<UpdateProductFormValues>({
    resolver: zodResolver(updateProductSchema),
  })

  // Load product data
  useEffect(() => {
    const fetchProduct = async () => {
      // Log product ID for debugging
      console.log('Product ID from params:', productId)
      console.log('Params object:', params)
      
      if (!productId || productId.trim() === '') {
        console.error('Product ID is empty or invalid')
        toast.error('Invalid product ID')
        router.push('/manager/catalog')
        return
      }

      // Check if productId contains invalid characters or is not a valid UUID format
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      if (!uuidRegex.test(productId)) {
        console.error('Product ID is not a valid UUID:', productId)
        toast.error('Invalid product ID format')
        router.push('/manager/catalog')
        return
      }

      try {
        setIsLoading(true)
        console.log('Fetching product with ID:', productId)
        const product = await getProduct(productId)
        
        if (!product || !product.id) {
          toast.error('Product not found')
          router.push('/manager/catalog')
          return
        }
        
        setCurrentProduct(product)
        
        // Check if product can be edited (only Draft products can be edited)
        // On Sale: stock_level > 0
        // Draft: stock_level === 0
        const isOnSale = product.stock_level > 0
        if (isOnSale) {
          toast.error('Products that are "On Sale" cannot be edited. Please discontinue the product first if you need to make changes.')
          router.push('/manager/catalog')
          return
        }
        
        // Parse category from description if it exists
        // Format: [Category] Description or Category: Description
        let descriptionText = product.description || ''
        let parsedCategory = ''
        
        // Try [Category] format first
        const bracketMatch = descriptionText.match(/^\[([^\]]+)\]\s*(.*)$/)
        if (bracketMatch) {
          parsedCategory = bracketMatch[1].trim()
          descriptionText = bracketMatch[2].trim()
          if (parsedCategory) {
            setSelectedCategory(parsedCategory)
          }
        } else {
          // Try Category: format
          const colonMatch = descriptionText.match(/^([^:]+):\s*(.*)$/)
          if (colonMatch) {
            parsedCategory = colonMatch[1].trim()
            descriptionText = colonMatch[2].trim()
            if (parsedCategory) {
              setSelectedCategory(parsedCategory)
            }
          }
        }
        
        // Also check if product has a category field directly
        if (!parsedCategory && product.category) {
          setSelectedCategory(product.category)
        }
        
        // Set form values
        reset({
          name: product.name,
          description: descriptionText,
          unit: product.unit,
          price: product.price,
          discount: product.discount || undefined,
          stock_level: product.stock_level,
          min_order_quantity: product.min_order_quantity,
        })

        // Set image URL if exists
        if (product.image_url) {
          setImageUrl(product.image_url)
        }
      } catch (error: any) {
        console.error('Failed to fetch product:', error)
        
        // Handle different error types with specific messages
        let errorMessage = 'Failed to load product'
        let shouldRedirect = true
        
        if (error.message) {
          errorMessage = error.message
          
          // Check if it's a 404 error (product not found)
          if (error.message.includes('not found') || error.message.includes('does not exist') || error.message.includes('deleted')) {
            errorMessage = 'This product no longer exists. It may have been deleted or the link is invalid.'
            // Show error message and redirect immediately
            toast.error(errorMessage, { duration: 3000 })
            router.push('/manager/catalog')
            setIsLoading(false)
            return
          }
          
          // Check for permission errors
          if (error.message.includes('permission') || error.message.includes('different supplier')) {
            errorMessage = 'You do not have permission to edit this product. It may belong to a different supplier.'
            toast.error(errorMessage, { duration: 3000 })
            router.push('/manager/catalog')
            setIsLoading(false)
            return
          }
          
          // Check for network/connection errors
          if (error.message.includes('connect') || error.message.includes('network') || error.message.includes('timeout')) {
            errorMessage = 'Cannot connect to server. Please check your connection and try again.'
            shouldRedirect = false // Don't redirect on network errors, let user retry
          }
        }
        
        toast.error(errorMessage, { duration: shouldRedirect ? 3000 : 5000 })
        
        // Only redirect for certain errors, not network errors
        if (shouldRedirect) {
          setTimeout(() => {
            router.push('/manager/catalog')
          }, 2000)
        }
      } finally {
        setIsLoading(false)
      }
    }

    fetchProduct()
  }, [productId, reset, router])

  function handleCategoryToggle(category: string) {
    // Only allow one category - if clicking the same category, deselect it
    setSelectedCategory(current => current === category ? null : category)
  }

  const handleAddCategory = () => {
    const trimmed = newCategory.trim()
    if (!trimmed || categories.includes(trimmed)) return
    // Set the new category as the selected one (replaces any existing selection)
    setSelectedCategory(trimmed)
    setNewCategory('')
  }

  function handleImageChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file) return
    setImageFile(file)
    setImagePreview(null) // Clear preview when new file selected
    const previewUrl = URL.createObjectURL(file)
    setImagePreview(previewUrl)
  }

  function handleDrop(event: React.DragEvent<HTMLLabelElement>) {
    event.preventDefault()
    const file = event.dataTransfer.files?.[0]
    if (!file) return
    setImageFile(file)
    setImagePreview(null) // Clear preview when new file selected
    const previewUrl = URL.createObjectURL(file)
    setImagePreview(previewUrl)
  }

  function handleDragOver(event: React.DragEvent<HTMLLabelElement>) {
    event.preventDefault()
  }

  const handleImageRemove = () => {
    setImageFile(null)
    setImagePreview(null)
    setImageUrl(null)
  }

  const handleImageUpload = async () => {
    if (!imageFile) return

    try {
      setIsUploading(true)
      const url = await uploadFile(imageFile)
      setImageUrl(url)
      setImagePreview(null) // Clear preview after upload
      toast.success('Image uploaded successfully')
    } catch (error) {
      console.error('Upload error:', error)
      toast.error(error instanceof Error ? error.message : 'Failed to upload image')
    } finally {
      setIsUploading(false)
    }
  }

  const onSubmit = async (data: UpdateProductFormValues) => {
    if (!productId || !currentProduct) return

    try {
      setIsSubmitting(true)

      // Upload image if file is selected but not yet uploaded
      let finalImageUrl = imageUrl
      if (imageFile && !imageUrl) {
        try {
          finalImageUrl = await uploadFile(imageFile)
        } catch (error) {
          toast.error('Failed to upload image. Please try again.')
          return
        }
      }

      // Prepare description with category prefix if category is selected
      // Format: [Category Name] Description
      let finalDescription = data.description || ''
      if (selectedCategory) {
        // Remove existing category prefix if exists
        finalDescription = finalDescription.replace(/^\[([^\]]+)\]\s*/, '').replace(/^([^:]+):\s*/, '')
        // Add category prefix
        finalDescription = `[${selectedCategory}] ${finalDescription}`.trim()
      }

      // Prepare product update data
      const updateData: any = {
        name: data.name,
        description: finalDescription || undefined,
        unit: data.unit,
        price: data.price,
        stock_level: data.stock_level,
        min_order_quantity: data.min_order_quantity,
        category: selectedCategory || undefined,
      }

      // Only include discount if it's different from current or if it's provided
      if (data.discount !== undefined) {
        if (data.discount === 0 || data.discount === null) {
          updateData.discount = 0 // Will clear discount in backend
        } else {
          updateData.discount = data.discount
        }
      }

      // Only update image_url if changed
      if (finalImageUrl !== currentProduct.image_url) {
        updateData.image_url = finalImageUrl || undefined
      }

      await updateProduct(productId, updateData)
      toast.success('Product updated successfully!')
      router.push('/manager/catalog')
    } catch (error: any) {
      console.error('Update product error:', error)
      const message = error.response?.data?.error?.message || error.message || 'Failed to update product'
      toast.error(message)
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isLoading) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <div className='text-sm text-neutral-500'>Loading product...</div>
      </div>
    )
  }

  if (!currentProduct) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <div className='text-sm text-neutral-500'>Product not found</div>
      </div>
    )
  }

  // Determine current status (only based on stock_level)
  const currentStatus: ProductStatus = currentProduct.stock_level > 0 ? 'On Sale' : 'Draft'

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Edit Product'
        description='Update product information, pricing, and inventory details.'
        cta={(
          <Link href='/manager/catalog' className='rounded-xl border border-neutral-200 px-4 py-2 text-sm font-semibold text-neutral-600 transition hover:border-primary-200 hover:text-primary-500'>
            Back to Catalog
          </Link>
        )}
      />

      <form onSubmit={handleSubmit(onSubmit)} className='space-y-8'>
        <SectionCard title='Media'>
          <div className='grid gap-4'>
            <label
              onDragOver={handleDragOver}
              onDrop={handleDrop}
              className='flex h-56 w-full cursor-pointer flex-col items-center justify-center rounded-2xl border border-dashed border-primary-200 bg-primary-50/40 text-sm text-primary-600 transition hover:border-primary-300 hover:bg-primary-50'
            >
              {imagePreview || imageUrl ? (
                <div className='relative h-full w-full'>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img 
                    src={imagePreview || imageUrl || ''} 
                    alt='Product preview' 
                    className='h-full w-full rounded-2xl object-cover' 
                  />
                  {imageFile && (
                    <button
                      type='button'
                      onClick={(e) => {
                        e.stopPropagation()
                        handleImageRemove()
                      }}
                      className='absolute right-2 top-2 rounded-full bg-rose-500 p-2 text-white shadow-lg transition hover:bg-rose-600'
                    >
                      <svg className='h-4 w-4' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                        <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M6 18L18 6M6 6l12 12' />
                      </svg>
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <span className='text-base font-semibold'>Drag & drop product photos</span>
                  <span className='mt-1 text-xs text-primary-500'>or click to browse from your device</span>
                </>
              )}
              <input
                type='file'
                accept='image/*'
                onChange={handleImageChange}
                className='hidden'
                disabled={isSubmitting || isUploading}
              />
            </label>
            {imageFile ? (
              <div className='flex items-center gap-3'>
                <p className='text-xs text-neutral-500'>Selected file: {imageFile.name}</p>
                {!imageUrl && (
                  <Button
                    type='button'
                    variant='secondary'
                    onClick={handleImageUpload}
                    disabled={isUploading || isSubmitting}
                    className='w-auto px-3 py-1 text-xs'
                  >
                    {isUploading ? 'Uploading...' : 'Upload Image'}
                  </Button>
                )}
                {imageUrl && !imagePreview && (
                  <span className='text-xs text-emerald-600'>✓ Current image</span>
                )}
                {imagePreview && imageUrl && (
                  <span className='text-xs text-amber-600'>⚠ New image ready to upload</span>
                )}
              </div>
            ) : imageUrl ? (
              <div className='flex items-center gap-3'>
                <p className='text-xs text-neutral-500'>Current image: {imageUrl.split('/').pop()}</p>
                <Button
                  type='button'
                  variant='secondary'
                  onClick={handleImageRemove}
                  disabled={isSubmitting}
                  className='w-auto px-3 py-1 text-xs text-rose-600 hover:bg-rose-50'
                >
                  Remove Image
                </Button>
              </div>
            ) : (
              <p className='text-xs text-neutral-500'>Recommended size: 1200 × 800 px. Landscape photos display best in the catalog listing.</p>
            )}
          </div>
        </SectionCard>

        <SectionCard title='Basic Information'>
          <div className='grid gap-6 md:grid-cols-2'>
            <div className='space-y-2'>
              <Label htmlFor='name'>Product Name *</Label>
              <Input
                id='name'
                {...register('name')}
                placeholder='e.g., Almaty Golden Apples'
                disabled={isSubmitting}
              />
              {errors.name && (
                <p className='text-sm text-rose-500'>{errors.name.message}</p>
              )}
            </div>
            <div className='space-y-2'>
              <Label htmlFor='sku'>Item Code</Label>
              <Input
                id='sku'
                value={`SKU-${currentProduct.id.replace(/-/g, '').substring(0, 8).toUpperCase()}`}
                disabled
                readOnly
                className='bg-neutral-50'
              />
              <p className='text-xs text-neutral-500'>Product ID: {currentProduct.id}</p>
            </div>
            <div className='space-y-2 md:col-span-2'>
              <Label htmlFor='description'>Description</Label>
              <textarea
                id='description'
                {...register('description')}
                className='h-28 w-full rounded-xl border border-neutral-200 bg-white px-3 py-2 text-sm text-neutral-700 shadow-sm transition focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-100'
                placeholder='Highlight origin, quality, and logistics notes for distributors.'
                disabled={isSubmitting}
              />
              {errors.description && (
                <p className='text-sm text-rose-500'>{errors.description.message}</p>
              )}
            </div>
          </div>
        </SectionCard>

        <SectionCard title='Categorisation & Status'>
          <div className='grid gap-6 md:grid-cols-2'>
            <div className='space-y-3'>
              <Label>Category (Optional)</Label>
              <div className='flex flex-wrap gap-2 rounded-xl border border-neutral-200 bg-neutral-50 p-4'>
                {categories.map(category => {
                  const selected = selectedCategory === category
                  return (
                    <button
                      key={category}
                      type='button'
                      onClick={() => handleCategoryToggle(category)}
                      disabled={isSubmitting}
                      className={`rounded-full border px-4 py-1 text-xs font-semibold transition ${selected
                        ? 'border-primary-200 bg-primary-100 text-primary-700'
                        : 'border-neutral-200 bg-white text-neutral-600 hover:border-primary-200 hover:text-primary-500'
                        }`}
                    >
                      {category}
                    </button>
                  )
                })}
              </div>
              <div className='flex items-center gap-3'>
                <Input
                  value={newCategory}
                  onChange={event => setNewCategory(event.target.value)}
                  placeholder='Add new category'
                  className='h-10 flex-1'
                  disabled={isSubmitting}
                />
                <Button type='button' variant='primary' className='w-auto px-4' onClick={handleAddCategory} disabled={isSubmitting}>
                  Add
                </Button>
              </div>
              {selectedCategory && (
                <p className='text-xs text-emerald-600'>Selected: {selectedCategory}</p>
              )}
              <p className='text-xs text-neutral-500'>Select one category for organization. Product status is determined by stock level: stock = 0 = Draft, stock &gt; 0 = On Sale.</p>
            </div>
            <div className='space-y-3'>
              <Label>Current Status</Label>
              <div className='flex flex-wrap gap-3'>
                {statusOptions.map(option => (
                  <button
                    key={option}
                    type='button'
                    disabled
                    className={`rounded-xl border px-4 py-2 text-sm font-semibold transition ${
                      option === currentStatus
                        ? 'border-primary-200 bg-primary-100 text-primary-700'
                        : 'border-neutral-200 bg-neutral-50 text-neutral-500'
                    }`}
                  >
                    {option}
                  </button>
                ))}
              </div>
              <p className='text-xs text-neutral-500'>
                Status: {currentStatus}. Change stock level to modify status. Stock = 0 = "Draft", stock &gt; 0 = "On Sale".
              </p>
            </div>
          </div>
        </SectionCard>

        <SectionCard title='Pricing & Inventory'>
          <div className='grid gap-6 md:grid-cols-3'>
            <div className='space-y-2'>
              <Label htmlFor='price'>Price (₸) *</Label>
              <Input
                id='price'
                type='number'
                min='0'
                step='0.01'
                placeholder='e.g., 4800'
                {...register('price', { valueAsNumber: true })}
                disabled={isSubmitting}
              />
              {errors.price && (
                <p className='text-sm text-rose-500'>{errors.price.message}</p>
              )}
            </div>
            <div className='space-y-2'>
              <Label htmlFor='unit'>Unit *</Label>
              <Input
                id='unit'
                {...register('unit')}
                placeholder='e.g., per crate (12kg)'
                disabled={isSubmitting}
              />
              {errors.unit && (
                <p className='text-sm text-rose-500'>{errors.unit.message}</p>
              )}
            </div>
            <div className='space-y-2'>
              <Label htmlFor='stock'>Available Stock *</Label>
              <Input
                id='stock'
                type='number'
                min='0'
                step='1'
                placeholder='e.g., 250'
                {...register('stock_level', { valueAsNumber: true })}
                disabled={isSubmitting}
              />
              {errors.stock_level && (
                <p className='text-sm text-rose-500'>{errors.stock_level.message}</p>
              )}
            </div>
            <div className='space-y-2'>
              <Label htmlFor='discount'>Discount (%)</Label>
              <Input
                id='discount'
                type='number'
                min='0'
                max='100'
                step='0.01'
                placeholder='e.g., 10'
                {...register('discount', { valueAsNumber: true })}
                disabled={isSubmitting}
              />
              {errors.discount && (
                <p className='text-sm text-rose-500'>{errors.discount.message}</p>
              )}
              <p className='text-xs text-neutral-500'>Discount is optional and will show original price with strikethrough and discounted price in red.</p>
            </div>
            <div className='space-y-2'>
              <Label htmlFor='min_order_quantity'>Minimum Order Quantity *</Label>
              <Input
                id='min_order_quantity'
                type='number'
                min='1'
                step='1'
                placeholder='e.g., 1'
                {...register('min_order_quantity', { valueAsNumber: true })}
                disabled={isSubmitting}
              />
              {errors.min_order_quantity && (
                <p className='text-sm text-rose-500'>{errors.min_order_quantity.message}</p>
              )}
            </div>
          </div>
        </SectionCard>

        <div className='flex flex-wrap gap-3'>
          <Button type='submit' disabled={isSubmitting || isUploading} className='w-auto px-6'>
            {isSubmitting ? 'Updating Product...' : 'Update Product'}
          </Button>
          <Link href='/manager/catalog'>
            <Button type='button' variant='secondary' disabled={isSubmitting} className='w-auto px-6'>
              Cancel
            </Button>
          </Link>
        </div>
      </form>
    </div>
  )
}

