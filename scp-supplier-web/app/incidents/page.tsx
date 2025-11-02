'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getComplaints, getComplaint, resolveComplaint, type ResolveComplaintData } from '@/lib/api/complaints'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { useAuthStore } from '@/lib/store/auth-store'
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
import { Badge } from '@/components/ui/badge'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import toast from 'react-hot-toast'
import { CheckCircle, AlertCircle } from 'lucide-react'
import { format } from 'date-fns'

const resolveSchema = z.object({
  resolution: z.string().min(10, 'Resolution must be at least 10 characters'),
})

type ResolveFormValues = z.infer<typeof resolveSchema>

export default function IncidentsPage() {
  const { hasPermission } = useAuthStore()
  const [selectedComplaint, setSelectedComplaint] = useState<string | null>(null)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
  const queryClient = useQueryClient()

  // Check if user has manager+ permissions
  if (!hasPermission('manager')) {
    return (
      <DashboardLayout>
        <div className="flex h-[60vh] items-center justify-center">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>Access Denied</CardTitle>
              <CardDescription>
                You need to be a Manager or Owner to access this page.
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </DashboardLayout>
    )
  }

  const { data: complaints, isLoading } = useQuery({
    queryKey: ['complaints'],
    queryFn: () => getComplaints(token || undefined),
    enabled: !!token,
  })

  const { data: complaintDetails } = useQuery({
    queryKey: ['complaint', selectedComplaint],
    queryFn: () => getComplaint(selectedComplaint!, token || undefined),
    enabled: !!selectedComplaint && isDialogOpen,
  })

  const resolveMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: ResolveComplaintData }) =>
      resolveComplaint(id, data, token || undefined),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['complaints'] })
      setIsDialogOpen(false)
      setSelectedComplaint(null)
      reset()
      toast.success('Complaint resolved successfully')
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to resolve complaint')
    },
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<ResolveFormValues>({
    resolver: zodResolver(resolveSchema),
  })

  const onSubmit = (data: ResolveFormValues) => {
    if (selectedComplaint) {
      resolveMutation.mutate({ id: selectedComplaint, data })
    }
  }

  const handleResolve = (complaintId: string) => {
    setSelectedComplaint(complaintId)
    setIsDialogOpen(true)
  }

  const getPriorityBadge = (priority: string) => {
    switch (priority) {
      case 'urgent':
        return <Badge variant="destructive">Urgent</Badge>
      case 'high':
        return <Badge className="bg-orange-100 text-orange-800">High</Badge>
      case 'medium':
        return <Badge className="bg-yellow-100 text-yellow-800">Medium</Badge>
      case 'low':
        return <Badge variant="secondary">Low</Badge>
      default:
        return <Badge>{priority}</Badge>
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'resolved':
        return <Badge className="bg-green-100 text-green-800">Resolved</Badge>
      case 'in_progress':
        return <Badge className="bg-blue-100 text-blue-800">In Progress</Badge>
      case 'escalated':
        return <Badge variant="destructive">Escalated</Badge>
      case 'open':
        return <Badge variant="secondary">Open</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  const openComplaints = complaints?.filter((c) => c.status !== 'resolved') || []

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Incident Management</h1>
          <p className="text-muted-foreground">
            Manage complaints escalated by Sales Representatives
          </p>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent"></div>
              <p className="mt-4 text-sm text-muted-foreground">Loading incidents...</p>
            </div>
          </div>
        ) : (
          <>
            {openComplaints.length > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Open Incidents</CardTitle>
                  <CardDescription>
                    Complaints requiring attention ({openComplaints.length})
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Title</TableHead>
                        <TableHead>Consumer</TableHead>
                        <TableHead>Priority</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead>Created</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {openComplaints.map((complaint) => (
                        <TableRow key={complaint.id}>
                          <TableCell className="font-medium">{complaint.title}</TableCell>
                          <TableCell>{complaint.consumerName || 'Unknown'}</TableCell>
                          <TableCell>{getPriorityBadge(complaint.priority)}</TableCell>
                          <TableCell>{getStatusBadge(complaint.status)}</TableCell>
                          <TableCell>
                            {format(new Date(complaint.createdAt), 'MMM d, yyyy')}
                          </TableCell>
                          <TableCell className="text-right">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleResolve(complaint.id)}
                            >
                              <CheckCircle className="mr-2 h-4 w-4" />
                              Resolve
                            </Button>
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
                <CardTitle>All Incidents</CardTitle>
                <CardDescription>
                  Complete incident history ({complaints?.length || 0})
                </CardDescription>
              </CardHeader>
              <CardContent>
                {complaints && complaints.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Title</TableHead>
                        <TableHead>Consumer</TableHead>
                        <TableHead>Priority</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead>Created</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {complaints.map((complaint) => (
                        <TableRow key={complaint.id}>
                          <TableCell className="font-medium">{complaint.title}</TableCell>
                          <TableCell>{complaint.consumerName || 'Unknown'}</TableCell>
                          <TableCell>{getPriorityBadge(complaint.priority)}</TableCell>
                          <TableCell>{getStatusBadge(complaint.status)}</TableCell>
                          <TableCell>
                            {format(new Date(complaint.createdAt), 'MMM d, yyyy')}
                          </TableCell>
                          <TableCell className="text-right">
                            {complaint.status !== 'resolved' && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleResolve(complaint.id)}
                              >
                                <CheckCircle className="mr-2 h-4 w-4" />
                                Resolve
                              </Button>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : (
                  <p className="text-center py-8 text-muted-foreground">No incidents found</p>
                )}
              </CardContent>
            </Card>
          </>
        )}

        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Resolve Incident</DialogTitle>
              <DialogDescription>
                Provide resolution details for this complaint
              </DialogDescription>
            </DialogHeader>
            {complaintDetails && (
              <div className="space-y-4">
                <div className="rounded-lg border p-4">
                  <h4 className="font-semibold mb-2">{complaintDetails.title}</h4>
                  <p className="text-sm text-muted-foreground mb-4">
                    {complaintDetails.description}
                  </p>
                  <div className="flex gap-4 text-sm">
                    <div>
                      <span className="font-medium">Consumer:</span>{' '}
                      {complaintDetails.consumerName || 'Unknown'}
                    </div>
                    <div>
                      <span className="font-medium">Priority:</span>{' '}
                      {getPriorityBadge(complaintDetails.priority)}
                    </div>
                  </div>
                </div>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="resolution">Resolution *</Label>
                    <Textarea
                      id="resolution"
                      rows={5}
                      placeholder="Describe how this incident was resolved..."
                      {...register('resolution')}
                    />
                    {errors.resolution && (
                      <p className="text-sm text-destructive">{errors.resolution.message}</p>
                    )}
                  </div>
                  <DialogFooter>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => {
                        setIsDialogOpen(false)
                        setSelectedComplaint(null)
                        reset()
                      }}
                    >
                      Cancel
                    </Button>
                    <Button type="submit" disabled={resolveMutation.isPending}>
                      {resolveMutation.isPending ? 'Resolving...' : 'Resolve Incident'}
                    </Button>
                  </DialogFooter>
                </form>
              </div>
            )}
          </DialogContent>
        </Dialog>
      </div>
    </DashboardLayout>
  )
}

