import { EllipsisVertical } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { StatusBadge } from '@/components/ui/status-badge'
import { FilterBar } from '@/components/dashboard/filter-bar'

// Map backend order status values to dashboard UI status types used in this table.
// Backend typically uses: 'pending', 'accepted', 'completed', 'rejected', 'cancelled'.
// Dashboard UI uses: 'approved' | 'pending' | 'not-started' | 'cancelled'.
export type OrderRowStatus = 'approved' | 'pending' | 'not-started' | 'cancelled'

export function mapBackendStatusToOrderRowStatus (status: string): OrderRowStatus {
  const normalized = status.toLowerCase()

  if (normalized === 'pending') return 'pending'
  if (normalized === 'accepted' || normalized === 'approved' || normalized === 'completed') return 'approved'
  if (normalized === 'cancelled' || normalized === 'canceled') return 'cancelled'
  // Treat any other state (e.g. 'rejected') as "not started" for dashboard purposes
  return 'not-started'
}

export interface OrderRow {
  id: string
  customer: string
  status: OrderRowStatus
  orderId: string
  billOfMaterials: string
  dueDate: string
  dueTime: string
}

interface OrdersTableProps {
  rows: OrderRow[]
  title: string
  subtitle: string
}

export function OrdersTable ({ rows, title, subtitle }: OrdersTableProps) {
  return (
    <Card>
      <div className='flex flex-col gap-6 p-6'>
        <div>
          <h2 className='text-xl font-semibold text-neutral-900'>{title}</h2>
          <p className='mt-1 text-sm text-neutral-500'>{subtitle}</p>
        </div>

        <FilterBar />

        <div className='overflow-x-auto'>
          <table className='min-w-full table-auto divide-y divide-neutral-100 text-left'>
            <thead className='text-xs uppercase tracking-[0.3em] text-neutral-500'>
              <tr>
                <th className='px-4 py-3'>
                  <input type='checkbox' className='h-4 w-4 rounded border-neutral-300 text-primary-500 focus:ring-primary-500' />
                </th>
                <th className='px-4 py-3'>Customer Name</th>
                <th className='px-4 py-3'>Status</th>
                <th className='px-4 py-3'>Order ID</th>
                <th className='px-4 py-3'>Bill of Materials</th>
                <th className='px-4 py-3'>Due Date</th>
                <th className='px-4 py-3 text-right'>Actions</th>
              </tr>
            </thead>
            <tbody className='divide-y divide-neutral-100 text-sm text-neutral-700'>
              {rows.map(row => (
                <tr key={row.id} className='transition hover:bg-neutral-50'>
                  <td className='px-4 py-4'>
                    <input type='checkbox' className='h-4 w-4 rounded border-neutral-300 text-primary-500 focus:ring-primary-500' />
                  </td>
                  <td className='px-4 py-4 font-medium text-neutral-900'>{row.customer}</td>
                  <td className='px-4 py-4'>
                    <StatusBadge
                      label={row.status === 'not-started' ? 'Not Started' : row.status}
                      variant={row.status}
                    />
                  </td>
                  <td className='px-4 py-4 font-medium text-neutral-900'>{row.orderId}</td>
                  <td className='px-4 py-4'>{row.billOfMaterials}</td>
                  <td className='px-4 py-4'>
                    <div className='flex flex-col'>
                      <span>{row.dueDate}</span>
                      <span className='text-xs text-neutral-400'>{row.dueTime}</span>
                    </div>
                  </td>
                  <td className='px-4 py-4 text-right'>
                    <button className='inline-flex h-9 w-9 items-center justify-center rounded-full border border-neutral-200 text-neutral-500 hover:bg-neutral-100'>
                      <EllipsisVertical className='h-5 w-5' />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className='flex items-center justify-between pt-2'>
          <p className='text-xs text-neutral-500'>Page 1 of 4</p>
          <div className='flex items-center gap-3'>
            <button className='inline-flex h-9 w-9 items-center justify-center rounded-full border border-neutral-200 text-neutral-500 hover:bg-neutral-100'>&lsaquo;</button>
            <button className='inline-flex h-9 w-9 items-center justify-center rounded-full border border-neutral-200 text-neutral-500 hover:bg-neutral-100'>&rsaquo;</button>
          </div>
        </div>
      </div>
    </Card>
  )
}


