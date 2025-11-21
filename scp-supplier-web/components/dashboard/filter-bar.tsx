import { ChevronDown, CalendarDays, SlidersHorizontal, Search } from 'lucide-react'

export function FilterBar () {
  return (
    <div className='flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-neutral-200 bg-white px-4 py-3'>
      <div className='flex flex-wrap items-center gap-3'>
        <button className='inline-flex items-center gap-2 rounded-xl border border-neutral-200 bg-neutral-50 px-3 py-2 text-sm font-medium text-neutral-600 hover:bg-white'>
          <CalendarDays className='h-4 w-4' />
          Last 30 days
          <ChevronDown className='h-4 w-4' />
        </button>

        <button className='inline-flex items-center gap-2 rounded-xl border border-neutral-200 bg-neutral-50 px-3 py-2 text-sm font-medium text-neutral-600 hover:bg-white'>
          <SlidersHorizontal className='h-4 w-4' />
          Filter by
          <ChevronDown className='h-4 w-4' />
        </button>
      </div>

      <div className='flex items-center gap-3'>
        <div className='relative'>
          <Search className='pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-neutral-400' />
          <input
            type='search'
            placeholder='Search orders'
            className='h-10 w-56 rounded-xl border border-neutral-200 bg-neutral-50 pl-9 pr-3 text-sm text-neutral-700 outline-none transition focus:border-primary-500 focus:bg-white focus:shadow-sm'
          />
        </div>
      </div>
    </div>
  )
}


