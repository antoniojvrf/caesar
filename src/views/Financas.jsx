import { useState } from 'react'
import { Card, StatCard } from '../components/Card.jsx'
import Modal from '../components/Modal.jsx'
import { ArrowDownRight, ArrowUpRight, TrendingUp, Trash2 } from 'lucide-react'
import { useAppState } from '../store/AppContext.jsx'
import { getFinancasSummary, formatBRL } from '../store/selectors.js'


export default function Financas() {
  const { state, dispatch } = useAppState()
  const [isCreating, setIsCreating] = useState(false)
  const [editingEntry, setEditingEntry] = useState(null)
  
  const summary = getFinancasSummary(state)

  const max = Math.max(1, ...state.monthlyFlow.flatMap((x) => [x.in, x.out]))

  const honorariosPagosTotal = state.honorarios
    .filter(h => h.status === 'pago')
    .reduce((s, h) => s + h.valor, 0)

  return (
    <div className="space-y-6 max-w-6xl">
      <div className="grid grid-cols-4 gap-4">
        <StatCard label="Entradas fixas" value={formatBRL(summary.entradasFixas)} hint="Salário + benefícios" accent="green" />
        <StatCard label="Entradas variáveis" value={formatBRL(summary.entradasVariaveis)} hint="Freela + dividendos + honorários" accent="green" />
        <StatCard label="Saídas projetadas" value={formatBRL(summary.saidasProjetadas)} hint="Boletos pendentes" accent="amber" />
        <StatCard label="Saldo final projetado" value={formatBRL(summary.saldoFinal)} hint="Após todas as saídas" accent={summary.saldoFinal >= 0 ? 'blue' : 'red'} />
      </div>

      <Card className="p-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold">Projeção de 12 meses</h2>
          <div className="flex items-center gap-3 text-xs">
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-sm bg-brand-green" /> Entradas
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-sm bg-brand-amber" /> Saídas
            </span>
          </div>
        </div>
        <div className="flex items-end gap-2 h-48">
          {state.monthlyFlow.map((x) => (
            <div key={x.month} className="flex-1 flex flex-col items-center gap-2">
              <div className="w-full flex items-end gap-1 h-40">
                <div className="flex-1 bg-brand-green/80 rounded-t" style={{ height: `${(x.in / max) * 100}%` }} />
                <div className="flex-1 bg-brand-amber/80 rounded-t" style={{ height: `${(x.out / max) * 100}%` }} />
              </div>
              <div className="text-xs text-neutral-500">{x.label}</div>
            </div>
          ))}
        </div>
      </Card>

      <div className="grid grid-cols-2 gap-4">
        <Card className="p-5">
          <div className="flex items-center gap-2 mb-3">
            <ArrowUpRight size={16} className="text-brand-green" />
            <h3 className="font-semibold">Entradas de abril</h3>
          </div>
          <div className="divide-y divide-neutral-100 dark:divide-neutral-800">
            {state.incomes.map((i) => (
              <div 
                key={i.id} 
                onClick={() => setEditingEntry(i)}
                className="py-2.5 flex items-center justify-between cursor-pointer hover:bg-neutral-50 dark:hover:bg-neutral-900 px-1 -mx-1 rounded-lg transition-colors group"
              >
                <div>
                  <div className="text-sm font-medium group-hover:text-brand-blue">{i.desc}</div>
                  <div className="text-xs text-neutral-500 capitalize">{i.type}</div>
                </div>
                <div className="text-sm font-semibold text-brand-green">{formatBRL(i.value)}</div>
              </div>
            ))}

            {honorariosPagosTotal > 0 && (
              <div className="py-2.5 flex items-center justify-between">
                <div>
                  <div className="text-sm font-medium">Honorários recebidos</div>
                  <div className="text-xs text-neutral-500">Painel do advogado</div>
                </div>
                <div className="text-sm font-semibold text-brand-green">{formatBRL(honorariosPagosTotal)}</div>
              </div>
            )}
          </div>
          <button onClick={() => setIsCreating(true)} className="mt-3 text-xs text-brand-blue hover:underline">+ Nova entrada</button>
        </Card>

        <Card className="p-5">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp size={16} className="text-brand-blue" />
            <h3 className="font-semibold">Insights</h3>
          </div>
          <div className="space-y-3 text-sm">
            <div className="flex items-start gap-2">
              <ArrowDownRight size={14} className="text-brand-green mt-0.5" />
              <div>Saídas projetadas: {formatBRL(summary.saidasProjetadas)}. Saldo favorável em {formatBRL(summary.saldoFinal)}.</div>
            </div>
            <div className="flex items-start gap-2">
              <TrendingUp size={14} className="text-brand-blue mt-0.5" />
              <div>Honorários recebidos no mês contribuem {formatBRL(honorariosPagosTotal)} às entradas variáveis.</div>
            </div>
            <div className="flex items-start gap-2">
              <ArrowUpRight size={14} className="text-brand-amber mt-0.5" />
              <div>
                {state.boletos.filter(b => b.status === 'pendente').length} boletos pendentes somam {formatBRL(state.boletos.filter(b => b.status === 'pendente').reduce((s, b) => s + b.value, 0))}.
              </div>
            </div>
          </div>
        </Card>
      </div>

      {(isCreating || editingEntry) && (
        <IncomeModal
          onClose={() => {
            setIsCreating(false)
            setEditingEntry(null)
          }}
          entry={editingEntry}
          onSubmit={(payload) => {
            if (editingEntry) {
              dispatch({ type: 'INCOME_UPDATE', payload: { id: editingEntry.id, patch: payload } })
            } else {
              dispatch({ type: 'INCOME_ADD', payload })
            }
            setIsCreating(false)
            setEditingEntry(null)
          }}
          onDelete={editingEntry ? (id) => {
            dispatch({ type: 'INCOME_DELETE', payload: id })
            setEditingEntry(null)
          } : null}
        />
      )}

    </div>
  )
}

function IncomeModal({ onClose, onSubmit, onDelete, entry }) {
  const [form, setForm] = useState({
    desc: entry?.desc || '',
    type: entry?.type || 'fixa',
    value: entry?.value || '',
    durationMonths: entry?.durationMonths || 1,
    startDate: entry?.startDate || new Date().toISOString().split('T')[0],
  })


  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(e) {
    e.preventDefault()
    if (!form.desc.trim() || !form.value) return
    onSubmit({
      desc: form.desc.trim(),
      type: form.type,
      value: Number(form.value),
      durationMonths: form.type === 'variável' ? Number(form.durationMonths) : null,
      startDate: form.type === 'variável' ? form.startDate : null,
    })
  }


  return (
    <Modal title="Nova entrada" subtitle="Registre uma nova receita para refletir nas finanças." onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <label className="block">
          <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Descrição</span>
          <input
            value={form.desc}
            onChange={(e) => update('desc', e.target.value)}
            placeholder="Ex.: Honorário consultivo"
            className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
          />
        </label>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Tipo</span>
            <select
              value={form.type}
              onChange={(e) => update('type', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              <option value="fixa">Fixa</option>
              <option value="variável">Variável</option>
            </select>
          </label>

          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Valor</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={form.value}
              onChange={(e) => update('value', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        {form.type === 'variável' && (
          <div className="grid grid-cols-2 gap-4 animate-in fade-in slide-in-from-top-2 duration-300">
            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Duração (meses)</span>
              <input
                type="number"
                min="1"
                max="60"
                value={form.durationMonths}
                onChange={(e) => update('durationMonths', e.target.value)}
                className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              />
            </label>

            <label className="block">
              <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Você vai começar a receber a partir de:</span>
              <input
                type="date"
                value={form.startDate}
                onChange={(e) => update('startDate', e.target.value)}
                className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
              />
            </label>

          </div>
        )}


        <div className="flex items-center justify-between pt-2">
          {entry ? (
            <button
              type="button"
              onClick={() => onDelete(entry.id)}
              className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 rounded-lg transition-colors"
            >
              <Trash2 size={14} />
              Excluir
            </button>
          ) : <div />}
          
          <div className="flex items-center gap-2">
            <button type="button" onClick={onClose} className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg">
              Cancelar
            </button>
            <button type="submit" className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700">
              {entry ? 'Atualizar entrada' : 'Salvar entrada'}
            </button>
          </div>
        </div>

      </form>
    </Modal>
  )
}
