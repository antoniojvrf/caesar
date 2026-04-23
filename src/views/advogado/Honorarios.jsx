import { useState } from 'react'
import { Card, StatCard } from '../../components/Card.jsx'
import Modal from '../../components/Modal.jsx'
import { Calendar as CalendarIcon, List } from 'lucide-react'
import { CalendarView, ToggleBtn, formatBRL, formatDateBR } from './_shared.jsx'
import { useAppState } from '../../store/AppContext.jsx'
import { getHonorariosSummary } from '../../store/selectors.js'

export default function Honorarios() {
  const { state, dispatch } = useAppState()
  const summary = getHonorariosSummary(state)
  const [mode, setMode] = useState('lista')
  const [cursor, setCursor] = useState({ y: 2026, m: 3 })
  const [isCreating, setIsCreating] = useState(false)
  const canCreateHonorario = state.processos.length > 0

  function toggleStatus(id, current) {
    const next = current === 'pago' ? 'pendente' : 'pago'
    dispatch({ type: 'HONORARIO_UPDATE_STATUS', payload: { id, status: next } })
  }

  return (
    <div className="space-y-4 max-w-6xl">
      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Total previsto" value={formatBRL(summary.total)} accent="blue" />
        <StatCard label="Pendente" value={formatBRL(summary.pendente)} accent="amber" />
        <StatCard label="Recebido" value={formatBRL(summary.recebido)} accent="green" />
      </div>

      <div className="flex items-center gap-1 p-1 bg-neutral-100 dark:bg-neutral-800/60 rounded-lg w-fit">
        <ToggleBtn active={mode === 'lista'} onClick={() => setMode('lista')} Icon={List} label="Lista" />
        <ToggleBtn active={mode === 'calendario'} onClick={() => setMode('calendario')} Icon={CalendarIcon} label="Calendário" />
      </div>

      <button
        onClick={() => canCreateHonorario && setIsCreating(true)}
        disabled={!canCreateHonorario}
        className="px-3 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700 w-fit disabled:opacity-50 disabled:hover:bg-brand-blue"
      >
        + Registrar honorário
      </button>
      {!canCreateHonorario && (
        <p className="text-xs text-neutral-500">Cadastre um processo antes de lançar honorários.</p>
      )}

      {mode === 'lista' ? (
        <Card className="overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-neutral-50 dark:bg-neutral-800/40 text-xs uppercase tracking-wide text-neutral-500">
              <tr>
                <th className="text-left px-4 py-3">Cliente</th>
                <th className="text-left px-4 py-3">Processo</th>
                <th className="text-left px-4 py-3">Tipo</th>
                <th className="text-left px-4 py-3">Vencimento</th>
                <th className="text-right px-4 py-3">Valor</th>
                <th className="text-center px-4 py-3">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100 dark:divide-neutral-800">
              {state.honorarios.map((h) => (
                <tr key={h.id} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                  <td className="px-4 py-3 font-medium">{h.cliente}</td>
                  <td className="px-4 py-3 font-mono text-xs text-neutral-500">{h.processo}</td>
                  <td className="px-4 py-3 text-neutral-600 dark:text-neutral-300">{h.tipo}</td>
                  <td className="px-4 py-3">{formatDateBR(h.venc)}</td>
                  <td className="px-4 py-3 text-right font-semibold">{formatBRL(h.valor)}</td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={() => toggleStatus(h.id, h.status)}>
                      <span className={`text-[10px] uppercase px-2 py-0.5 rounded-full font-semibold cursor-pointer hover:opacity-80 ${
                        h.status === 'pago'
                          ? 'bg-brand-green/10 text-brand-green'
                          : 'bg-brand-amber/10 text-brand-amber'
                      }`}>
                        {h.status}
                      </span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      ) : (
        <CalendarView cursor={cursor} setCursor={setCursor} items={state.honorarios} />
      )}

      {isCreating && (
        <NewHonorarioModal
          processos={state.processos}
          onClose={() => setIsCreating(false)}
          onCreate={(payload) => {
            dispatch({ type: 'HONORARIO_ADD', payload })
            setIsCreating(false)
          }}
        />
      )}
    </div>
  )
}

function NewHonorarioModal({ processos, onClose, onCreate }) {
  const [form, setForm] = useState({
    processoId: processos[0]?.id ?? '',
    tipo: '',
    venc: '',
    valor: '',
    status: 'pendente',
  })

  const processoSelecionado = processos.find((processo) => processo.id === form.processoId)

  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(e) {
    e.preventDefault()
    if (!processoSelecionado || !form.tipo.trim() || !form.venc || !form.valor) return
    onCreate({
      processoId: processoSelecionado.id,
      cliente: processoSelecionado.cliente,
      processo: processoSelecionado.numero.slice(0, 10),
      tipo: form.tipo.trim(),
      venc: form.venc,
      valor: Number(form.valor),
      status: form.status,
    })
  }

  return (
    <Modal title="Novo honorário" subtitle="Registre uma cobrança vinculada a um processo." onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <label className="block">
          <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Processo</span>
          <select
            value={form.processoId}
            onChange={(e) => update('processoId', e.target.value)}
            className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
          >
            {processos.map((processo) => (
              <option key={processo.id} value={processo.id}>{processo.cliente} · {processo.numero}</option>
            ))}
          </select>
        </label>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Tipo</span>
            <input
              value={form.tipo}
              onChange={(e) => update('tipo', e.target.value)}
              placeholder="Ex.: Parcela 01/03"
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Status</span>
            <select
              value={form.status}
              onChange={(e) => update('status', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              <option value="pendente">Pendente</option>
              <option value="pago">Pago</option>
            </select>
          </label>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Vencimento</span>
            <input
              type="date"
              value={form.venc}
              onChange={(e) => update('venc', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Valor</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={form.valor}
              onChange={(e) => update('valor', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="flex items-center justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg">
            Cancelar
          </button>
          <button type="submit" className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700">
            Salvar honorário
          </button>
        </div>
      </form>
    </Modal>
  )
}
