'use client'

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  getConsumerLinks,
  approveConsumerLink,
  rejectConsumerLink,
  blockConsumerLink,
} from '@/lib/api/consumers'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
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
import { Check, X, Ban } from 'lucide-react'
import { format } from 'date-fns'

export default function ConsumersPage() {
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
  const queryClient = useQueryClient()

  const { data: links, isLoading } = useQuery({
    queryKey: ['consumer-links'],
    queryFn: () => getConsumerLinks(token || undefined),
    enabled: !!token,
  })

  const approveMutation = useMutation({
    mutationFn: (linkId: string) => approveConsumerLink(linkId, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['consumer-links'] })
      toast.success('Consumer link approved')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to approve link')
    },
  })

  const rejectMutation = useMutation({
    mutationFn: (linkId: string) => rejectConsumerLink(linkId, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['consumer-links'] })
      toast.success('Consumer link rejected')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to reject link')
    },
  })

  const blockMutation = useMutation({
    mutationFn: (linkId: string) => blockConsumerLink(linkId, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['consumer-links'] })
      toast.success('Consumer link blocked')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to block consumer link')
    },
  })

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="secondary">Pending</Badge>
      case 'approved':
        return <Badge className="bg-green-100 text-green-800">Approved</Badge>
      case 'rejected':
        return <Badge variant="destructive">Rejected</Badge>
      case 'blocked':
        return <Badge variant="destructive">Blocked</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  const pendingLinks = links?.filter((link) => link.status === 'pending') || []
  const activeLinks = links?.filter((link) => link.status === 'approved') || []

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Consumer Links</h1>
          <p className="text-muted-foreground">Manage consumer link requests and connections</p>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
              <p className="mt-4 text-sm text-muted-foreground">Loading consumer links...</p>
            </div>
          </div>
        ) : (
          <>
            {pendingLinks.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Pending Requests</CardTitle>
                  <CardDescription>Consumer link requests awaiting your approval</CardDescription>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Consumer</TableHead>
                        <TableHead>Email</TableHead>
                        <TableHead>Requested</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {pendingLinks.map((link) => (
                        <TableRow key={link.id}>
                          <TableCell className="font-medium">
                            {link.consumerName || 'Unknown'}
                          </TableCell>
                          <TableCell>{link.consumerEmail}</TableCell>
                          <TableCell>
                            {format(new Date(link.requestedAt), 'MMM d, yyyy')}
                          </TableCell>
                          <TableCell>{getStatusBadge(link.status)}</TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => approveMutation.mutate(link.id)}
                                disabled={approveMutation.isPending}
                              >
                                <Check className="mr-2 h-4 w-4" />
                                Approve
                              </Button>
                              <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => rejectMutation.mutate(link.id)}
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
                <CardTitle>Active Consumer Links</CardTitle>
                <CardDescription>
                  Approved consumer connections ({activeLinks.length})
                </CardDescription>
              </CardHeader>
              <CardContent>
                {activeLinks.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Consumer</TableHead>
                        <TableHead>Email</TableHead>
                        <TableHead>Approved</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {activeLinks.map((link) => (
                        <TableRow key={link.id}>
                          <TableCell className="font-medium">
                            {link.consumerName || 'Unknown'}
                          </TableCell>
                          <TableCell>{link.consumerEmail}</TableCell>
                          <TableCell>
                            {link.approvedAt
                              ? format(new Date(link.approvedAt), 'MMM d, yyyy')
                              : '-'}
                          </TableCell>
                          <TableCell>{getStatusBadge(link.status)}</TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => blockMutation.mutate(link.id)}
                                disabled={blockMutation.isPending}
                              >
                                <Ban className="mr-2 h-4 w-4" />
                                Block
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <p className="text-center py-8 text-muted-foreground">
                    No active consumer links
                  </p>
                )}
              </CardContent>
            </Card>
          </>
        )}
      </div>
    </DashboardLayout>
  )
}

