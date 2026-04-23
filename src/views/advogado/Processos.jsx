import { useState } from 'react'
import { Card } from '../../components/Card.jsx'
import Modal from '../../components/Modal.jsx'
import { useAppState } from '../../store/AppContext.jsx'
import { formatBRL, formatDateBR } from '../../store/selectors.js'

export default function Processos() {
  const { state, dispatch } = useAppState()
  const [isCreating, setIsCreating] = useState(false)

  return (
    <div className="space-y-5 max-w-6xl">
      <Card className="overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-neutral-50 dark:bg-neutral-800/40 text-xs uppercase tracking-wide text-neutral-500">
            <tr>
              <th className="text-left px-4 py-3">Processo</th>
              <th className="text-left px-4 py-3">Cliente</th>
              <th className="text-left px-4 py-3">Área</th>
              <th className="text-left px-4 py-3">Fase</th>
              <th className="text-left px-4 py-3">Próximo ato</th>
              <th className="text-right px-4 py-3">Valor da causa</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-neutral-100 dark:divide-neutral-800">
            {state.processos.map((p) => (
              <tr key={p.id} className="hover:bg-neutral-50 dark:hover:bg-neutral-800/40 cursor-pointer">
                <td className="px-4 py-3 font-mono text-xs">{p.numero}</td>
                <td className="px-4 py-3 font-medium">{p.cliente}</td>
                <td className="px-4 py-3">
                  <span className="text-[10px] uppercase px-2 py-0.5 rounded-full bg-brand-blue/10 text-brand-blue font-semibold">
                    {p.area}
                  </span>
                </td>
                <td className="px-4 py-3 text-neutral-600 dark:text-neutral-300">{p.fase}</td>
                <td className="px-4 py-3 text-neutral-600 dark:text-neutral-300">
                  {formatDateBR(p.proxAto)} · {p.proxAtoDesc}
                </td>
                <td className="px-4 py-3 text-right font-semibold">{formatBRL(p.valorCausa)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="px-4 py-3 border-t border-neutral-100 dark:border-neutral-800">
          <button onClick={() => setIsCreating(true)} className="text-xs text-brand-blue hover:underline">+ Cadastrar processo</button>
        </div>
      </Card>

      {isCreating && (
        <NewProcessoModal
          onClose={() => setIsCreating(false)}
          onCreate={(payload) => {
            dispatch({ type: 'PROCESSO_ADD', payload })
            setIsCreating(false)
          }}
        />
      )}
    </div>
  )
}

function NewProcessoModal({ onClose, onCreate }) {
  const [form, setForm] = useState({
    numero: '',
    cliente: '',
    area: 'Cível',
    fase: 'Inicial',
    proxAto: '',
    proxAtoDesc: '',
    valorCausa: '',
    exitoPercentual: '',
    exitoProbabilidade: 'média',
    exitoPrazo: '',
  })

  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(e) {
    e.preventDefault()
    if (!form.numero.trim() || !form.cliente.trim() || !form.proxAto || !form.valorCausa) return
    onCreate({
      ...form,
      numero: form.numero.trim(),
      cliente: form.cliente.trim(),
      proxAtoDesc: form.proxAtoDesc.trim() || 'Acompanhar andamento',
      valorCausa: Number(form.valorCausa),
      exitoPercentual: Number(form.exitoPercentual || 0),
      exitoPrazo: form.exitoPrazo.trim(),
    })
  }

  return (
    <Modal title="Novo processo" subtitle="Cadastre um processo real para refletir nos painéis do advogado." onClose={onClose} maxWidth="max-w-2xl">
      <form onSubmit={submit} className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Número</span>
            <input
              value={form.numero}
              onChange={(e) => update('numero', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Cliente</span>
            <input
              value={form.cliente}
              onChange={(e) => update('cliente', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Área</span>
            <input
              value={form.area}
              onChange={(e) => update('area', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Fase</span>
            <input
              value={form.fase}
              onChange={(e) => update('fase', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Valor da causa</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={form.valorCausa}
              onChange={(e) => update('valorCausa', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Próximo ato</span>
            <input
              type="date"
              value={form.proxAto}
              onChange={(e) => update('proxAto', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Descrição do ato</span>
            <input
              value={form.proxAtoDesc}
              onChange={(e) => update('proxAtoDesc', e.target.value)}
              placeholder="Ex.: Audiência de instrução"
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Êxito %</span>
            <input
              type="number"
              min="0"
              max="100"
              value={form.exitoPercentual}
              onChange={(e) => update('exitoPercentual', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Probabilidade</span>
            <select
              value={form.exitoProbabilidade}
              onChange={(e) => update('exitoProbabilidade', e.target.value)}
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            >
              <option value="alta">Alta</option>
              <option value="média">Média</option>
              <option value="baixa">Baixa</option>
            </select>
          </label>
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Prazo de êxito</span>
            <input
              value={form.exitoPrazo}
              onChange={(e) => update('exitoPrazo', e.target.value)}
              placeholder="Ex.: Dez/2026"
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="flex items-center justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg">
            Cancelar
          </button>
          <button type="submit" className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700">
            Salvar processo
          </button>
        </div>
      </form>
    </Modal>
  )
}
