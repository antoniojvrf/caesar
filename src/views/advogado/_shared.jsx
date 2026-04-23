import { Card } from '../../components/Card.jsx'
import { ChevronLeft, ChevronRight } from 'lucide-react'

export function formatBRL(v) {
  return v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 })
}

export function formatDateBR(iso) {
  const [y, m, d] = iso.split('-')
  return `${d}/${m}/${y}`
}

export function ToggleBtn({ active, onClick, Icon, label }) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition ${
        active ? 'bg-white dark:bg-neutral-900 shadow-sm' : 'text-neutral-500 hover:text-neutral-800'
      }`}
    >
      <Icon size={13} />
      {label}
    </button>
  )
}

export const MONTH_NAMES = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
export const WEEK_DAYS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']

export function CalendarView({ cursor, setCursor, items }) {
  const first = new Date(cursor.y, cursor.m, 1)
  const daysInMonth = new Date(cursor.y, cursor.m + 1, 0).getDate()
  const startDow = first.getDay()
  const cells = []
  for (let i = 0; i < startDow; i++) cells.push(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(d)
  while (cells.length % 7 !== 0) cells.push(null)

  function itemsOn(day) {
    return items.filter((h) => {
      const [y, m, d] = h.venc.split('-').map(Number)
      return y === cursor.y && m - 1 === cursor.m && d === day
    })
  }

  function prev() {
    setCursor((c) => (c.m === 0 ? { y: c.y - 1, m: 11 } : { ...c, m: c.m - 1 }))
  }
  function next() {
    setCursor((c) => (c.m === 11 ? { y: c.y + 1, m: 0 } : { ...c, m: c.m + 1 }))
  }

  return (
    <Card className="p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold">
          {MONTH_NAMES[cursor.m]} {cursor.y}
        </h3>
        <div className="flex items-center gap-1">
          <button onClick={prev} className="p-1.5 rounded hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <ChevronLeft size={16} />
          </button>
          <button onClick={next} className="p-1.5 rounded hover:bg-neutral-100 dark:hover:bg-neutral-800">
            <ChevronRight size={16} />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-7 gap-1 text-[11px] uppercase tracking-wide text-neutral-500 mb-1">
        {WEEK_DAYS.map((d) => (
          <div key={d} className="px-2 py-1 text-center">
            {d}
          </div>
        ))}
      </div>

      <div className="grid grid-cols-7 gap-1">
        {cells.map((day, idx) => {
          const dayItems = day ? itemsOn(day) : []
          return (
            <div
              key={idx}
              className={`min-h-[92px] p-2 rounded-lg border ${
                day
                  ? 'bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800'
                  : 'bg-transparent border-transparent'
              }`}
            >
              {day && (
                <>
                  <div className="text-xs font-semibold text-neutral-600 dark:text-neutral-300">{day}</div>
                  <div className="mt-1 space-y-1">
                    {dayItems.map((h, i) => (
                      <div
                        key={i}
                        className={`text-[10px] px-1.5 py-0.5 rounded truncate ${
                          h.status === 'pago'
                            ? 'bg-brand-green/15 text-brand-green'
                            : 'bg-brand-amber/15 text-brand-amber'
                        }`}
                        title={`${h.cliente} — ${formatBRL(h.valor)}`}
                      >
                        {formatBRL(h.valor)} · {h.cliente.split(' ')[0]}
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          )
        })}
      </div>
    </Card>
  )
}
