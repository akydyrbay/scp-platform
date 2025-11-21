import { ArrowUpRight, Factory, BarChart3 } from 'lucide-react'
import { Card } from '@/components/ui/card'

interface CapacityMetrics {
  totalMachines: number
  productionRate: string
}

interface InventorySummary {
  totalRequests: number
  approved: number
  pending: number
}

interface MetricsPanelProps {
  capacity: CapacityMetrics
  inventory: InventorySummary
}

export function MetricsPanel ({ capacity, inventory }: MetricsPanelProps) {
  return (
    <div className='grid gap-6'>
      <Card className='p-6'>
        <div className='flex items-start justify-between'>
          <div>
            <p className='text-sm font-medium text-neutral-500 uppercase tracking-[0.3em]'>Machinery Capacity</p>
            <div className='mt-6 flex items-end gap-6'>
              <div>
                <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Total Machines</p>
                <p className='mt-2 text-4xl font-semibold text-neutral-900'>{capacity.totalMachines}</p>
              </div>
              <div>
                <p className='text-xs uppercase tracking-[0.3em] text-neutral-400'>Production Rate</p>
                <p className='mt-2 flex items-center gap-2 text-2xl font-semibold text-success'>
                  {capacity.productionRate}
                  <ArrowUpRight className='h-5 w-5' />
                </p>
              </div>
            </div>

            <div className='mt-6 flex flex-wrap gap-3'>
              <button className='inline-flex items-center gap-2 rounded-full border border-primary-100 bg-primary-50 px-4 py-2 text-sm font-medium text-primary-600 hover:bg-white'>
                <Factory className='h-4 w-4' />
                View Shop Floor
              </button>
              <button className='inline-flex items-center gap-2 rounded-full border border-neutral-200 px-4 py-2 text-sm font-medium text-neutral-600 hover:bg-neutral-50'>
                <BarChart3 className='h-4 w-4' />
                View More
              </button>
            </div>
          </div>
        </div>
      </Card>

      <Card className='p-6'>
        <p className='text-sm font-medium text-neutral-500 uppercase tracking-[0.3em]'>Inventory Requests</p>
        <p className='mt-2 text-3xl font-semibold text-neutral-900'>{inventory.totalRequests}</p>
        <p className='mt-1 text-sm text-neutral-500'>Requests awaiting your approval</p>

        <div className='mt-5 grid grid-cols-2 gap-4 text-sm text-neutral-600'>
          <div className='rounded-xl bg-emerald-50 px-4 py-3 text-emerald-600'>
            <p className='text-xs uppercase tracking-[0.3em] text-emerald-500'>Approved</p>
            <p className='mt-2 text-lg font-semibold'>{inventory.approved}</p>
          </div>
          <div className='rounded-xl bg-amber-50 px-4 py-3 text-amber-600'>
            <p className='text-xs uppercase tracking-[0.3em] text-amber-500'>Pending</p>
            <p className='mt-2 text-lg font-semibold'>{inventory.pending}</p>
          </div>
        </div>

        <button className='mt-6 w-full rounded-xl bg-primary-500 py-3 text-sm font-semibold text-white shadow-[0px_14px_30px_rgba(59,130,246,0.35)] transition hover:bg-primary-600'>
          Create Request
        </button>
      </Card>
    </div>
  )
}


