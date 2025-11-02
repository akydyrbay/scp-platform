'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getOrders, acceptOrder, rejectOrder, getOrder } from '@/lib/api/orders'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import toast from 'react-hot-toast'
import { Check, X, Eye } from 'lucide-react'
import { format } from 'date-fns'

export default function OrdersPage() {
  const [selectedOrder, setSelectedOrder] = useState<string | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
  const queryClient = useQueryClient()

  const { data: orders, isLoading } = useQuery({
    queryKey: ['orders'],
    queryFn: () => getOrders(token || undefined),
    enabled: !!token,
  })

  const { data: orderDetails } = useQuery({
    queryKey: ['order', selectedOrder],
    queryFn: () => getOrder(selectedOrder!, token || undefined),
    enabled: !!selectedOrder && isDialogOpen,
  })

  const acceptMutation = useMutation({
    mutationFn: (orderId: string) => acceptOrder(orderId, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] })
      toast.success('Order accepted')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to accept order')
    },
  })

  const rejectMutation = useMutation({
    mutationFn: (orderId: string) => rejectOrder(orderId, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] })
      toast.success('Order rejected')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to reject order')
    },
  })

  const handleViewOrder = (orderId: string) => {
    setSelectedOrder(orderId)
    setIsDialogOpen(true)
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="secondary">Pending</Badge>
      case 'accepted':
        return <Badge className="bg-green-100 text-green-800">Accepted</Badge>
      case 'rejected':
        return <Badge variant="destructive">Rejected</Badge>
      case 'completed':
        return <Badge className="bg-blue-100 text-blue-800">Completed</Badge>
      case 'cancelled':
        return <Badge variant="destructive">Cancelled</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  const pendingOrders = orders?.filter((order) => order.status === 'pending') || []
  const allOrders = orders || []

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Orders</h1>
          <p className="text-muted-foreground">Manage bulk orders from consumers</p>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
              <p className="mt-4 text-sm text-muted-foreground">Loading orders...</p>
            </div>
          </div>
        ) : (
          <>
            {pendingOrders.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Pending Orders</CardTitle>
                  <CardDescription>
                    Orders awaiting your approval ({pendingOrders.length})
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Order ID</TableHead>
                        <TableHead>Consumer</TableHead>
                        <TableHead>Total</TableHead>
                        <TableHead>Date</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {pendingOrders.map((order) => (
                        <TableRow key={order.id}>
                          <TableCell className="font-medium">
                            #{order.id.slice(-8)}
                          </TableCell>
                          <TableCell>{order.consumerName || 'Unknown'}</TableCell>
                          <TableCell>${order.total.toFixed(2)}</TableCell>
                          <TableCell>{format(new Date(order.createdAt), 'MMM d, yyyy')}</TableCell>
                          <TableCell>{getStatusBadge(order.status)}</TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleViewOrder(order.id)}
                              >
                                <Eye className="mr-2 h-4 w-4" />
                                View
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                className="text-green-600 hover:text-green-700"
                                onClick={() => acceptMutation.mutate(order.id)}
                                disabled={acceptMutation.isPending}
                              >
                                <Check className="mr-2 h-4 w-4" />
                                Accept
                              </Button>
                              <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => rejectMutation.mutate(order.id)}
                                disabled={rejectMutation.isPending}
                              >
                                <X className="mr-2 h-4 w-4" />
                                Reject
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            )}

            <Card>
              <CardHeader>
                <CardTitle>All Orders</CardTitle>
                <CardDescription>Complete order history ({allOrders.length})</CardDescription>
              </CardHeader>
              <CardContent>
                {allOrders.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Order ID</TableHead>
                        <TableHead>Consumer</TableHead>
                        <TableHead>Total</TableHead>
                        <TableHead>Date</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {allOrders.map((order) => (
                        <TableRow key={order.id}>
                          <TableCell className="font-medium">
                            #{order.id.slice(-8)}
                          </TableCell>
                          <TableCell>{order.consumerName || 'Unknown'}</TableCell>
                          <TableCell>${order.total.toFixed(2)}</TableCell>
                          <TableCell>{format(new Date(order.createdAt), 'MMM d, yyyy')}</TableCell>
                          <TableCell>{getStatusBadge(order.status)}</TableCell>
                          <TableCell className="text-right">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleViewOrder(order.id)}
                            >
                              <Eye className="mr-2 h-4 w-4" />
                              View
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <p className="text-center py-8 text-muted-foreground">No orders found</p>
                )}
              </CardContent>
            </Card>
          </>
        )}

        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Order Details</DialogTitle>
              <DialogDescription>Order #{orderDetails?.id.slice(-8)}</DialogDescription>
            </DialogHeader>
            {orderDetails && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Consumer</p>
                    <p className="text-sm">{orderDetails.consumerName || 'Unknown'}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Status</p>
                    <div className="mt-1">{getStatusBadge(orderDetails.status)}</div>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Date</p>
                    <p className="text-sm">{format(new Date(orderDetails.createdAt), 'MMM d, yyyy')}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Total</p>
                    <p className="text-sm font-semibold">${orderDetails.total.toFixed(2)}</p>
                  </div>
                </div>
                <div>
                  <p className="mb-2 text-sm font-medium">Order Items</p>
                  <div className="space-y-2">
                    {orderDetails.items.map((item) => (
                      <div
                        key={item.id}
                        className="flex items-center justify-between rounded border p-2"
                      >
                        <div>
                          <p className="text-sm font-medium">{item.productName || 'Product'}</p>
                          <p className="text-xs text-muted-foreground">
                            Qty: {item.quantity} × ${item.unitPrice.toFixed(2)}
                          </p>
                        </div>
                        <p className="text-sm font-semibold">${item.subtotal.toFixed(2)}</p>
                      </div>
                    ))}
                  </div>
                </div>
                <div className="flex justify-end gap-2 border-t pt-4">
                  {orderDetails.status === 'pending' && (
                    <>
                      <Button
                        variant="outline"
                        className="text-green-600 hover:text-green-700"
                        onClick={() => {
                          acceptMutation.mutate(orderDetails.id)
                          setIsDialogOpen(false)
                        }}
                        disabled={acceptMutation.isPending}
                      >
                        <Check className="mr-2 h-4 w-4" />
                        Accept Order
                      </Button>
                      <Button
                        variant="destructive"
                        onClick={() => {
                          rejectMutation.mutate(orderDetails.id)
                          setIsDialogOpen(false)
                        }}
                        disabled={rejectMutation.isPending}
                      >
                        <X className="mr-2 h-4 w-4" />
                        Reject Order
                      </Button>
                    </>
                  )}
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>
      </div>
    </DashboardLayout>
  )
}

