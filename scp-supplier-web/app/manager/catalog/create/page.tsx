'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
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
import { createProduct } from '@/lib/api/products'
import { uploadFile } from '@/lib/api/upload'

const initialCategories = ['Fresh Fruit', 'Meat', 'Dairy', 'Bakery', 'Seasonal', 'Organic']
const statusOptions = ['On Sale', 'Draft'] as const

type ProductStatus = (typeof statusOptions)[number]

const createProductSchema = z.object({
  name: z.string().min(1, 'Product name is required'),
  description: z.string().optional(),
  unit: z.string().min(1, 'Unit is required'),
  price: z.number().min(0.01, 'Price must be greater than 0'),
  discount: z.number().min(0).max(100).optional(),
  stock_level: z.number().int().min(0, 'Stock level must be 0 or greater'),
  min_order_quantity: z.number().int().min(1, 'Minimum order quantity must be at least 1'),
})

type CreateProductFormValues = z.infer<typeof createProductSchema>

export default function ManagerCatalogCreatePage() {
  const router = useRouter()
  const [categories] = useState(initialCategories)
  const [selectedCategories, setSelectedCategories] = useState<string[]>([])
  const [newCategory, setNewCategory] = useState('')
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isUploading, setIsUploading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<CreateProductFormValues>({
    resolver: zodResolver(createProductSchema),
    defaultValues: {
      stock_level: 0,
      min_order_quantity: 1,
      discount: undefined,
    },
  })

  function handleCategoryToggle(category: string) {
    setSelectedCategories(current =>
      current.includes(category)
        ? current.filter(item => item !== category)
        : [...current, category]
    )
  }

  const handleAddCategory = () => {
    const trimmed = newCategory.trim()
    if (!trimmed || categories.includes(trimmed)) return
    // Categories are for display only, not stored in backend
    setSelectedCategories((prev: string[]) => [...prev, trimmed])
    setNewCategory('')
  }

  function handleImageChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file) return
    setImageFile(file)
    const previewUrl = URL.createObjectURL(file)
    setImagePreview(previewUrl)
  }

  function handleDrop(event: React.DragEvent<HTMLLabelElement>) {
    event.preventDefault()
    const file = event.dataTransfer.files?.[0]
    if (!file) return
    setImageFile(file)
    const previewUrl = URL.createObjectURL(file)
    setImagePreview(previewUrl)
  }

  function handleDragOver(event: React.DragEvent<HTMLLabelElement>) {
    event.preventDefault()
  }

  const handleImageUpload = async () => {
    if (!imageFile) return

    try {
      setIsUploading(true)
      const url = await uploadFile(imageFile)
      setImageUrl(url)
      toast.success('Image uploaded successfully')
    } catch (error) {
      console.error('Upload error:', error)
      toast.error(error instanceof Error ? error.message : 'Failed to upload image')
    } finally {
      setIsUploading(false)
    }
  }

  const onSubmit = async (data: CreateProductFormValues) => {
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

      // Prepare description
      let finalDescription = data.description || ''

      // Prepare product data
      const productData = {
        name: data.name,
        description: finalDescription || undefined,
        image_url: finalImageUrl || undefined,
        unit: data.unit,
        price: data.price,
        discount: data.discount || undefined,
        stock_level: data.stock_level,
        min_order_quantity: data.min_order_quantity,
        category: selectedCategories.length > 0 ? selectedCategories[0] : undefined,
      }

      await createProduct(productData)
      toast.success('Product created successfully!')
      router.push('/manager/catalog')
    } catch (error: any) {
      console.error('Create product error:', error)
      const message = error.response?.data?.error?.message || error.message || 'Failed to create product'
      toast.error(message)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className='space-y-10'>
      <PageHeader
        title='Create Product'
        description='Add a new marketplace item to the supplier catalog. Complete all required details before publishing.'
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
                // eslint-disable-next-line @next/next/no-img-element
                <img src={imagePreview || imageUrl || ''} alt='Product preview' className='h-full w-full rounded-2xl object-cover' />
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
                {imageUrl && (
                  <span className='text-xs text-emerald-600'>✓ Uploaded</span>
                )}
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
              <Label htmlFor='sku'>Item Code (Optional)</Label>
              <Input
                id='sku'
                placeholder='e.g., ID-01234'
                disabled={isSubmitting}
                readOnly
              />
              <p className='text-xs text-neutral-500'>Auto-generated from product ID</p>
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
              <Label>Categories (Optional)</Label>
              <div className='flex flex-wrap gap-2 rounded-xl border border-neutral-200 bg-neutral-50 p-4'>
                {categories.map(category => {
                  const selected = selectedCategories.includes(category)
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
              <p className='text-xs text-neutral-500'>Categories are for organization only. Product status is determined by stock level: stock = 0 = Draft, stock &gt; 0 = On Sale.</p>
            </div>
            <div className='space-y-3'>
              <Label>Product Status</Label>
              <div className='flex flex-wrap gap-3'>
                {statusOptions.map(option => (
                  <button
                    key={option}
                    type='button'
                    disabled
                    className='rounded-xl border border-neutral-200 bg-neutral-50 px-4 py-2 text-sm font-semibold text-neutral-500'
                  >
                    {option}
                  </button>
                ))}
              </div>
              <p className='text-xs text-neutral-500'>Status is determined by stock level only. New products start as "Draft" (stock = 0). Use "Publish" button in catalog to set to "On Sale" (stock &gt; 0).</p>
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
            {isSubmitting ? 'Creating Product...' : 'Save Product'}
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

