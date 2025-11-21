import { EllipsisVertical } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { StatusBadge } from '@/components/ui/status-badge'
import { FilterBar } from '@/components/dashboard/filter-bar'

interface RequestRow {
  id: string
  description: string
  quantity: number
  status: 'approved' | 'pending'
  dueDate: string
  comments: string
}

interface RequestsTableProps {
  rows: RequestRow[]
}

export function RequestsTable ({ rows }: RequestsTableProps) {
  return (
    <Card>
      <div className='flex flex-col gap-6 p-6'>
        <div className='flex items-start justify-between'>
          <div>
            <h2 className='text-xl font-semibold text-neutral-900'>Inventory Requests</h2>
            <p className='mt-1 text-sm text-neutral-500'>You have requests awaiting your approval</p>
          </div>
          <button className='rounded-xl bg-primary-500 px-4 py-2 text-sm font-semibold text-white shadow-[0px_12px_24px_rgba(59,130,246,0.35)] transition hover:bg-primary-600'>
            Create Request
          </button>
        </div>

        <FilterBar />

        <div className='overflow-x-auto'>
          <table className='min-w-full table-auto divide-y divide-neutral-100 text-left'>
            <thead className='text-xs uppercase tracking-[0.3em] text-neutral-500'>
              <tr>
                <th className='px-4 py-3'>No.</th>
                <th className='px-4 py-3'>Order ID</th>
                <th className='px-4 py-3'>Description</th>
                <th className='px-4 py-3 text-center'>Qty</th>
                <th className='px-4 py-3'>Approval Status</th>
                <th className='px-4 py-3'>Due Date</th>
                <th className='px-4 py-3'>Comments</th>
                <th className='px-4 py-3 text-right'>Actions</th>
              </tr>
            </thead>
            <tbody className='divide-y divide-neutral-100 text-sm text-neutral-700'>
              {rows.map((row, index) => (
                <tr key={row.id} className='transition hover:bg-neutral-50'>
                  <td className='px-4 py-4 font-medium text-neutral-900'>{index + 1}</td>
                  <td className='px-4 py-4 font-medium text-neutral-900'>{row.id}</td>
                  <td className='px-4 py-4'>{row.description}</td>
                  <td className='px-4 py-4 text-center font-semibold text-neutral-900'>{row.quantity}</td>
                  <td className='px-4 py-4'>
                    <StatusBadge label={row.status} variant={row.status} />
                  </td>
                  <td className='px-4 py-4'>{row.dueDate}</td>
                  <td className='px-4 py-4'>{row.comments}</td>
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
      </div>
    </Card>
  )
}


