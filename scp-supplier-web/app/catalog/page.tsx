'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  getProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  bulkUpdateProducts,
  type CreateProductData,
  type UpdateProductData,
  type BulkUpdateData,
} from '@/lib/api/products'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import toast from 'react-hot-toast'
import { Plus, Edit, Trash2, Package } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import Image from 'next/image'

const productSchema = z.object({
  name: z.string().min(1, 'Product name is required'),
  description: z.string().optional(),
  imageUrl: z.string().url('Invalid URL').optional().or(z.literal('')),
  unit: z.string().min(1, 'Unit is required'),
  price: z.number().min(0, 'Price must be positive'),
  discount: z.number().min(0).max(100).optional(),
  stockLevel: z.number().min(0, 'Stock level must be non-negative'),
  minOrderQuantity: z.number().min(1, 'Minimum order quantity must be at least 1'),
})

type ProductFormValues = z.infer<typeof productSchema>

export default function CatalogPage() {
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState<string | null>(null)
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
  const queryClient = useQueryClient()

  const { data: products, isLoading } = useQuery({
    queryKey: ['products'],
    queryFn: () => getProducts(token || undefined),
    enabled: !!token,
  })

  const createMutation = useMutation({
    mutationFn: (data: CreateProductData) => createProduct(data, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      setIsDialogOpen(false)
      reset()
      toast.success('Product created successfully')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to create product')
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateProductData }) =>
      updateProduct(id, data, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      setIsDialogOpen(false)
      setEditingProduct(null)
      reset()
      toast.success('Product updated successfully')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to update product')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (productId: string) => deleteProduct(productId, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      toast.success('Product deleted successfully')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to delete product')
    },
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<ProductFormValues>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      stockLevel: 0,
      minOrderQuantity: 1,
      price: 0,
    },
  })

  const onSubmit = (data: ProductFormValues) => {
    if (editingProduct) {
      updateMutation.mutate({ id: editingProduct, data })
    } else {
      createMutation.mutate(data)
    }
  }

  const handleEdit = (productId: string) => {
    const product = products?.find((p) => p.id === productId)
    if (product) {
      setEditingProduct(productId)
      setValue('name', product.name)
      setValue('description', product.description || '')
      setValue('imageUrl', product.imageUrl || '')
      setValue('unit', product.unit)
      setValue('price', product.price)
      setValue('discount', product.discount || 0)
      setValue('stockLevel', product.stockLevel)
      setValue('minOrderQuantity', product.minOrderQuantity)
      setIsDialogOpen(true)
    }
  }

  const handleDelete = (productId: string, productName: string) => {
    if (confirm(`Are you sure you want to delete ${productName}?`)) {
      deleteMutation.mutate(productId)
    }
  }

  const handleDialogClose = () => {
    setIsDialogOpen(false)
    setEditingProduct(null)
    reset()
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Catalog & Inventory</h1>
            <p className="text-muted-foreground">Manage your products and inventory</p>
          </div>
          <Dialog open={isDialogOpen} onOpenChange={handleDialogClose}>
            <DialogTrigger asChild>
              <Button onClick={() => setEditingProduct(null)}>
                <Plus className="mr-2 h-4 w-4" />
                Add Product
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>
                  {editingProduct ? 'Edit Product' : 'Create New Product'}
                </DialogTitle>
                <DialogDescription>
                  {editingProduct
                    ? 'Update product information'
                    : 'Add a new product to your catalog'}
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Product Name *</Label>
                  <Input id="name" {...register('name')} />
                  {errors.name && (
                    <p className="text-sm text-destructive">{errors.name.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="description">Description</Label>
                  <Textarea
                    id="description"
                    {...register('description')}
                    rows={3}
                  />
                  {errors.description && (
                    <p className="text-sm text-destructive">{errors.description.message}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="imageUrl">Image URL</Label>
                  <Input
                    id="imageUrl"
                    type="url"
                    placeholder="https://example.com/image.jpg"
                    {...register('imageUrl')}
                  />
                  {errors.imageUrl && (
                    <p className="text-sm text-destructive">{errors.imageUrl.message}</p>
                  )}
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="unit">Unit *</Label>
                    <Input id="unit" placeholder="kg, pcs, etc." {...register('unit')} />
                    {errors.unit && (
                      <p className="text-sm text-destructive">{errors.unit.message}</p>
                    )}
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="price">Price *</Label>
                    <Input
                      id="price"
                      type="number"
                      step="0.01"
                      {...register('price', { valueAsNumber: true })}
                    />
                    {errors.price && (
                      <p className="text-sm text-destructive">{errors.price.message}</p>
                    )}
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="discount">Discount (%)</Label>
                    <Input
                      id="discount"
                      type="number"
                      min="0"
                      max="100"
                      {...register('discount', { valueAsNumber: true })}
                    />
                    {errors.discount && (
                      <p className="text-sm text-destructive">{errors.discount.message}</p>
                    )}
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="minOrderQuantity">Min Order Qty *</Label>
                    <Input
                      id="minOrderQuantity"
                      type="number"
                      min="1"
                      {...register('minOrderQuantity', { valueAsNumber: true })}
                    />
                    {errors.minOrderQuantity && (
                      <p className="text-sm text-destructive">
                        {errors.minOrderQuantity.message}
                      </p>
                    )}
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="stockLevel">Stock Level *</Label>
                  <Input
                    id="stockLevel"
                    type="number"
                    min="0"
                    {...register('stockLevel', { valueAsNumber: true })}
                  />
                  {errors.stockLevel && (
                    <p className="text-sm text-destructive">{errors.stockLevel.message}</p>
                  )}
                </div>
                <DialogFooter>
                  <Button type="button" variant="outline" onClick={handleDialogClose}>
                    Cancel
                  </Button>
                  <Button
                    type="submit"
                    disabled={createMutation.isPending || updateMutation.isPending}
                  >
                    {createMutation.isPending || updateMutation.isPending
                      ? 'Saving...'
                      : editingProduct
                      ? 'Update Product'
                      : 'Create Product'}
                  </Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Products</CardTitle>
            <CardDescription>Your product catalog</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="text-center">
                  <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
                  <p className="mt-4 text-sm text-muted-foreground">Loading products...</p>
                </div>
              </div>
            ) : products && products.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Product</TableHead>
                    <TableHead>Unit</TableHead>
                    <TableHead>Price</TableHead>
                    <TableHead>Stock</TableHead>
                    <TableHead>Min Order</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {products.map((product) => (
                    <TableRow key={product.id}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          {product.imageUrl ? (
                            <Image
                              src={product.imageUrl}
                              alt={product.name}
                              width={40}
                              height={40}
                              className="rounded"
                            />
                          ) : (
                            <div className="flex h-10 w-10 items-center justify-center rounded bg-muted">
                              <Package className="h-5 w-5 text-muted-foreground" />
                            </div>
                          )}
                          <div>
                            <p className="font-medium">{product.name}</p>
                            {product.discount && product.discount > 0 && (
                              <Badge variant="secondary" className="mt-1">
                                {product.discount}% off
                              </Badge>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{product.unit}</TableCell>
                      <TableCell>
                        ${product.price.toFixed(2)}
                        {product.discount && product.discount > 0 && (
                          <span className="ml-2 text-xs text-muted-foreground line-through">
                            ${(product.price / (1 - product.discount / 100)).toFixed(2)}
                          </span>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge
                          variant={product.stockLevel < 10 ? 'destructive' : 'secondary'}
                        >
                          {product.stockLevel} {product.unit}
                        </Badge>
                      </TableCell>
                      <TableCell>{product.minOrderQuantity}</TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleEdit(product.id)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleDelete(product.id, product.name)}
                            disabled={deleteMutation.isPending}
                          >
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <p className="text-center py-8 text-muted-foreground">No products found</p>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  )
}

