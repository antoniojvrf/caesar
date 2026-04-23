import { Home, Receipt, CheckSquare, Target, TrendingUp, Tag, Settings, Sparkles, Briefcase, FileText, Trophy, BarChart3 } from 'lucide-react'

const sections = [
  {
    label: 'Pessoal',
    items: [
      { id: 'dashboard', label: 'Dashboard', Icon: Home },
      { id: 'boletos', label: 'Boletos & Contas', Icon: Receipt },
      { id: 'tarefas', label: 'Tarefas', Icon: CheckSquare },
      { id: 'metas', label: 'Metas', Icon: Target },
      { id: 'financas', label: 'Finanças', Icon: TrendingUp },
      { id: 'categorias', label: 'Categorias', Icon: Tag },
    ],
  },
  {
    label: 'Painel do Advogado',
    items: [
      { id: 'adv_processos', label: 'Processos', Icon: Briefcase },
      { id: 'adv_honorarios', label: 'Honorários a Receber', Icon: FileText },
      { id: 'adv_exito', label: 'Previstos em Êxito', Icon: Trophy },
      { id: 'adv_indicadores', label: 'Indicadores', Icon: BarChart3 },
    ],
  },
  {
    label: 'Sistema',
    items: [{ id: 'config', label: 'Configurações', Icon: Settings }],
  },
]

export default function Sidebar({ current, onChange }) {
  return (
    <aside className="w-60 shrink-0 bg-white/90 dark:bg-neutral-900/80 backdrop-blur border-r border-neutral-200 dark:border-neutral-800 flex flex-col">
      <div className="px-5 h-14 flex items-center gap-2 border-b border-neutral-200 dark:border-neutral-800">
        <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-brand-blue to-brand-green flex items-center justify-center">
          <Sparkles size={16} className="text-white" />
        </div>
        <div className="font-semibold tracking-tight">MyLife</div>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-4 overflow-y-auto">
        {sections.map((sec) => (
          <div key={sec.label}>
            <div className="px-3 text-[10px] uppercase tracking-wider font-semibold text-neutral-400 mb-1.5">
              {sec.label}
            </div>
            <div className="space-y-1">
              {sec.items.map(({ id, label, Icon }) => {
                const active = current === id
                return (
                  <button
                    key={id}
                    onClick={() => onChange(id)}
                    className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                      active
                        ? 'bg-brand-blue/10 text-brand-blue dark:bg-brand-blue/20 font-medium'
                        : 'text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800/60'
                    }`}
                  >
                    <Icon size={16} />
                    {label}
                  </button>
                )
              })}
            </div>
          </div>
        ))}
      </nav>

      <div className="p-4 border-t border-neutral-200 dark:border-neutral-800 text-xs text-neutral-500 dark:text-neutral-400">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-brand-green" />
          Sincronizado localmente
        </div>
      </div>
    </aside>
  )
}
