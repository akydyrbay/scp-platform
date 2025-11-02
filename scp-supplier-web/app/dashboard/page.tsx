'use client'

import { useQuery } from '@tanstack/react-query'
import { getDashboardStats } from '@/lib/api/dashboard'
import { useAuthStore } from '@/lib/store/auth-store'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { ShoppingCart, Link as LinkIcon, Package, AlertCircle } from 'lucide-react'

export default function DashboardPage() {
  const { user } = useAuthStore()
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null

  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: () => getDashboardStats(token || undefined),
    enabled: !!token,
  })

  const metrics = [
    {
      title: 'Total Orders',
      value: stats?.totalOrders || 0,
      description: `${stats?.pendingOrders || 0} pending`,
      icon: ShoppingCart,
      color: 'text-blue-600',
    },
    {
      title: 'Pending Link Requests',
      value: stats?.pendingLinkRequests || 0,
      description: 'Awaiting approval',
      icon: LinkIcon,
      color: 'text-orange-600',
    },
    {
      title: 'Low Stock Items',
      value: stats?.lowStockItems || 0,
      description: 'Need restocking',
      icon: Package,
      color: 'text-red-600',
    },
    {
      title: 'Recent Activity',
      value: stats?.recentOrders?.length || 0,
      description: 'Last 7 days',
      icon: AlertCircle,
      color: 'text-green-600',
    },
  ]

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back, {user?.firstName || user?.email}
          </p>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
              <p className="mt-4 text-sm text-muted-foreground">Loading dashboard...</p>
            </div>
          </div>
        ) : (
          <>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              {metrics.map((metric) => {
                const Icon = metric.icon
                return (
                  <Card key={metric.title}>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">{metric.title}</CardTitle>
                      <Icon className={`h-4 w-4 ${metric.color}`} />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{metric.value}</div>
                      <p className="text-xs text-muted-foreground">{metric.description}</p>
                    </CardContent>
                  </Card>
                )
              })}
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle>Recent Orders</CardTitle>
                  <CardDescription>Latest orders from consumers</CardDescription>
                </CardHeader>
                <CardContent>
                  {stats?.recentOrders && stats.recentOrders.length > 0 ? (
                    <div className="space-y-4">
                      {stats.recentOrders.slice(0, 5).map((order) => (
                        <div
                          key={order.id}
                          className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0"
                        >
                          <div>
                            <p className="text-sm font-medium">
                              Order #{order.id.slice(-8)}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {order.consumerName || 'Unknown Consumer'} • ${order.total.toFixed(2)}
                            </p>
                          </div>
                          <span
                            className={`rounded-full px-2 py-1 text-xs font-medium ${
                              order.status === 'pending'
                                ? 'bg-yellow-100 text-yellow-800'
                                : order.status === 'accepted'
                                ? 'bg-green-100 text-green-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}
                          >
                            {order.status}
                          </span>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground">No recent orders</p>
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Low Stock Items</CardTitle>
                  <CardDescription>Products that need restocking</CardDescription>
                </CardHeader>
                <CardContent>
                  {stats?.lowStockProducts && stats.lowStockProducts.length > 0 ? (
                    <div className="space-y-4">
                      {stats.lowStockProducts.slice(0, 5).map((product) => (
                        <div
                          key={product.id}
                          className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0"
                        >
                          <div>
                            <p className="text-sm font-medium">{product.name}</p>
                            <p className="text-xs text-muted-foreground">
                              Stock: {product.stockLevel} {product.unit}
                            </p>
                          </div>
                          <span className="rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-800">
                            Low Stock
                          </span>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground">All products are well stocked</p>
                  )}
                </CardContent>
              </Card>
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  )
}

