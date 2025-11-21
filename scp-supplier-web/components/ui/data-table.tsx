import type { ReactNode } from 'react'

interface DataTableProps {
  headers: string[]
  rows: ReactNode[][]
  emptyMessage: string
}

export function DataTable ({ headers, rows, emptyMessage }: DataTableProps) {
  const hasRows = rows.length > 0

  return (
    <div className='overflow-hidden rounded-2xl border border-slate-200/60 bg-white'>
      <table className='w-full min-w-max divide-y divide-slate-100 text-left'>
        <thead className='bg-slate-50 text-slate-500 uppercase text-xs tracking-[0.3em]'>
          <tr>
            {headers.map(header => (
              <th key={header} className='px-6 py-3 font-medium'>{header}</th>
            ))}
          </tr>
        </thead>
        <tbody className='divide-y divide-slate-100 text-sm text-slate-700'>
          {hasRows
            ? rows.map((cols, index) => (
              <tr key={index} className='hover:bg-slate-50 transition'>
                {cols.map((col, colIndex) => (
                  <td key={colIndex} className='px-6 py-4 align-top'>
                    {col}
                  </td>
                ))}
              </tr>
              ))
            : (
              <tr>
                <td colSpan={headers.length} className='px-6 py-12 text-center text-slate-400'>
                  {emptyMessage}
                </td>
              </tr>
              )}
        </tbody>
      </table>
    </div>
  )
}

