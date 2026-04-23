import { Card, StatCard } from '../components/Card.jsx'
import { AlertCircle, CheckCircle2, Clock, TrendingUp, Gavel } from 'lucide-react'
import { useAppState } from '../store/AppContext.jsx'
import { getDashboardStats, formatBRL, formatDateBR } from '../store/selectors.js'

export default function Dashboard() {
  const { state } = useAppState()
  const { tasksDueToday, boletosDue, proximosAtos, financas, metasAtivas } = getDashboardStats(state)

  const catMap = Object.fromEntries(state.categorias.map(c => [c.id, c.name]))

  const boletosPendentes = state.boletos.filter(b => b.status !== 'pago').length
  const vencendo3d = (() => {
    const in3 = new Date()
    in3.setDate(in3.getDate() + 3)
    const in3Str = in3.toISOString().split('T')[0]
    return state.boletos.filter(b => b.status !== 'pago' && b.dueDate <= in3Str).length
  })()

  return (
    <div className="space-y-6 max-w-6xl">
      <div className="grid grid-cols-4 gap-4">
        <StatCard
          label="A pagar este mês"
          value={formatBRL(financas.saidasProjetadas)}
          hint={`${boletosPendentes} boletos pendentes`}
          accent="amber"
        />
        <StatCard
          label="Entradas projetadas"
          value={formatBRL(financas.entradasFixas + financas.entradasVariaveis)}
          hint="Salários + honorários recebidos"
          accent="green"
        />
        <StatCard
          label="Saldo projetado"
          value={formatBRL(financas.saldoFinal)}
          hint="após pagamentos"
          accent="blue"
        />
        <StatCard
          label="Metas ativas"
          value={String(metasAtivas)}
          hint={`${state.metas.filter(m => m.type === 'financeira').length} financeiras · ${state.metas.filter(m => m.type === 'pessoal').length} pessoais`}
          accent="green"
        />
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Card className="col-span-2 p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold">Próximos vencimentos</h2>
            <span className="text-xs text-neutral-500">{boletosDue.length} nos próximos 7 dias</span>
          </div>
          {boletosDue.length === 0 ? (
            <p className="text-sm text-neutral-500">Nenhum boleto vencendo nos próximos 7 dias.</p>
          ) : (
            <div className="divide-y divide-neutral-100 dark:divide-neutral-800">
              {boletosDue.map(b => (
                <div key={b.id} className="py-3 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-lg bg-brand-blue/10 text-brand-blue flex items-center justify-center">
                      <Clock size={16} />
                    </div>
                    <div>
                      <div className="font-medium text-sm">{catMap[b.categoriaId] ?? '—'}</div>
                      <div className="text-xs text-neutral-500">Vence em {formatDateBR(b.dueDate)}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-semibold">{formatBRL(b.value)}</span>
                    <span className={`text-[10px] uppercase px-2 py-0.5 rounded-full font-medium ${
                      b.status === 'recorrente'
                        ? 'bg-brand-green/10 text-brand-green'
                        : 'bg-brand-amber/10 text-brand-amber'
                    }`}>
                      {b.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold">Tarefas de hoje</h2>
            <span className="text-xs text-neutral-500">{tasksDueToday.length} pendentes</span>
          </div>
          <div className="space-y-2">
            {tasksDueToday.length === 0 ? (
              <p className="text-sm text-neutral-500">Nenhuma tarefa para hoje.</p>
            ) : (
              tasksDueToday.map(t => (
                <div key={t.id} className="flex items-center gap-3 p-2 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800/50">
                  <CheckCircle2 size={18} className="text-neutral-300 dark:text-neutral-600" />
                  <span className="text-sm">{t.title}</span>
                </div>
              ))
            )}
          </div>

          {proximosAtos.length > 0 && (
            <div className="mt-5 pt-4 border-t border-neutral-100 dark:border-neutral-800">
              <div className="flex items-center gap-1.5 text-xs font-semibold text-neutral-500 uppercase tracking-wide mb-2">
                <Gavel size={12} /> Próximos atos
              </div>
              <div className="space-y-1.5">
                {proximosAtos.map(p => (
                  <div key={p.id} className="text-xs flex items-center justify-between">
                    <span className="text-neutral-700 dark:text-neutral-200 truncate flex-1">{p.cliente}</span>
                    <span className="text-neutral-500 ml-2 shrink-0">{formatDateBR(p.proxAto)} · {p.proxAtoDesc}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="mt-4 p-3 rounded-lg bg-brand-blue/5 border border-brand-blue/10">
            <div className="flex items-start gap-2">
              <TrendingUp size={16} className="text-brand-blue mt-0.5" />
              <div>
                <div className="text-sm font-medium">Saldo do mês</div>
                <div className={`text-xs mt-0.5 font-semibold ${financas.saldoFinal >= 0 ? 'text-brand-green' : 'text-brand-red'}`}>
                  {formatBRL(financas.saldoFinal)}
                </div>
              </div>
            </div>
          </div>
        </Card>
      </div>

      {vencendo3d > 0 && (
        <Card className="p-5">
          <div className="flex items-center gap-2 mb-1">
            <AlertCircle size={16} className="text-brand-amber" />
            <h2 className="font-semibold">Alertas</h2>
          </div>
          <div className="text-sm text-neutral-600 dark:text-neutral-300">
            {vencendo3d} {vencendo3d === 1 ? 'boleto vence' : 'boletos vencem'} nos próximos 3 dias. Acesse Boletos & Contas para revisar.
          </div>
        </Card>
      )}
    </div>
  )
}
