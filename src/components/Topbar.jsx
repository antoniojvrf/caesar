import { Search, Plus, Bell, LogOut } from 'lucide-react'

export default function Topbar({ title, username, onLogout }) {
  return (
    <header className="h-14 shrink-0 border-b border-neutral-200 dark:border-neutral-800 bg-white/70 dark:bg-neutral-900/60 backdrop-blur flex items-center justify-between px-6">
      <h1 className="text-lg font-semibold tracking-tight">{title}</h1>
      <div className="flex items-center gap-2">
        <div className="relative">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
          <input
            placeholder="Buscar..."
            className="pl-9 pr-3 py-1.5 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-neutral-50 dark:bg-neutral-800/50 w-64 focus:outline-none focus:border-brand-blue"
          />
        </div>
        <button className="p-2 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800">
          <Bell size={16} />
        </button>
        <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-brand-blue text-white text-sm font-medium hover:bg-blue-700 transition">
          <Plus size={14} /> Novo
        </button>
        <div className="hidden sm:flex items-center gap-2 ml-3 pl-3 border-l border-neutral-200 dark:border-neutral-800">
          <div className="text-right">
            <div className="text-xs text-neutral-500 dark:text-neutral-400">Sessão local</div>
            <div className="text-sm font-medium">{username}</div>
          </div>
          <button
            type="button"
            onClick={onLogout}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-neutral-200 dark:border-neutral-700 text-sm font-medium hover:bg-neutral-100 dark:hover:bg-neutral-800 transition"
          >
            <LogOut size={14} /> Sair
          </button>
        </div>
      </div>
    </header>
  )
}
