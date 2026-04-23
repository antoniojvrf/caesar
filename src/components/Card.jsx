export function Card({ children, className = '', ...props }) {
  return (
    <div
      className={`bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-xl ${className}`}
      {...props}
    >
      {children}
    </div>
  )
}

export function StatCard({ label, value, hint, accent = 'blue' }) {
  const accents = {
    blue: 'text-brand-blue',
    green: 'text-brand-green',
    amber: 'text-brand-amber',
    red: 'text-brand-red',
  }
  return (
    <Card className="p-5">
      <div className="text-xs uppercase tracking-wide text-neutral-500 dark:text-neutral-400">{label}</div>
      <div className={`mt-2 text-2xl font-semibold ${accents[accent]}`}>{value}</div>
      {hint && <div className="mt-1 text-xs text-neutral-500 dark:text-neutral-400">{hint}</div>}
    </Card>
  )
}
