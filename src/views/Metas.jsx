import { useState } from 'react'
import { Card } from '../components/Card.jsx'
import Modal from '../components/Modal.jsx'
import { Target, DollarSign, Heart, BookOpen, CheckCircle2 } from 'lucide-react'
import { useAppState } from '../store/AppContext.jsx'
import { formatBRL } from '../store/selectors.js'

const typeIcon = { financeira: DollarSign, pessoal: Heart }
const fallbackIcon = BookOpen

export default function Metas() {
  const { state, dispatch } = useAppState()
  const [isCreating, setIsCreating] = useState(false)

  function toggleMilestone(metaId, index) {
    dispatch({ type: 'META_MILESTONE_TOGGLE', payload: { metaId, index } })
  }

  return (
    <div className="space-y-4 max-w-6xl">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold tracking-tight">Metas</h2>
          <p className="text-sm text-neutral-500 mt-0.5">Acompanhe objetivos financeiros e pessoais com progresso real.</p>
        </div>
        <button
          onClick={() => setIsCreating(true)}
          className="px-3 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700"
        >
          + Nova meta
        </button>
      </div>

      <div className="grid grid-cols-2 gap-4">
        {state.metas.map((g) => {
          const Icon = typeIcon[g.type] ?? fallbackIcon
          return (
            <Card key={g.id} className="p-5">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    g.type === 'financeira' ? 'bg-brand-blue/10 text-brand-blue' : 'bg-brand-green/10 text-brand-green'
                  }`}>
                    <Icon size={18} />
                  </div>
                  <div>
                    <div className="font-semibold">{g.title}</div>
                    <div className="text-xs text-neutral-500 capitalize">Meta {g.type} · prazo {g.deadline}</div>
                  </div>
                </div>
                <Target size={16} className="text-neutral-300" />
              </div>

              <div className="mt-4">
                <div className="flex items-center justify-between text-xs mb-1.5">
                  <span className="text-neutral-500">
                    {g.current != null && g.target != null
                      ? `${formatBRL(g.current)} de ${formatBRL(g.target)}`
                      : 'Progresso'}
                  </span>
                  <span className="font-semibold">{g.progress}%</span>
                </div>
                <div className="h-2 rounded-full bg-neutral-100 dark:bg-neutral-800 overflow-hidden">
                  <div
                    className={`h-full ${g.type === 'financeira' ? 'bg-brand-blue' : 'bg-brand-green'}`}
                    style={{ width: `${g.progress}%` }}
                  />
                </div>
              </div>

              <div className="mt-4 space-y-1.5">
                {g.milestones.map((m, i) => (
                  <button
                    key={m.label}
                    onClick={() => toggleMilestone(g.id, i)}
                    className="flex items-center gap-2 text-xs w-full text-left"
                  >
                    <CheckCircle2
                      size={14}
                      className={m.done ? 'text-brand-green' : 'text-neutral-300 dark:text-neutral-600'}
                    />
                    <span className={m.done ? 'line-through text-neutral-400' : ''}>{m.label}</span>
                  </button>
                ))}
              </div>
            </Card>
          )
        })}
      </div>

      {isCreating && (
        <NewMetaModal
          onClose={() => setIsCreating(false)}
          onCreate={(payload) => {
            dispatch({ type: 'META_ADD', payload })
            setIsCreating(false)
          }}
        />
      )}
    </div>
  )
}

function NewMetaModal({ onClose, onCreate }) {
  const [form, setForm] = useState({
    title: '',
    type: 'pessoal',
    current: '',
    target: '',
    deadline: '',
    milestones: '',
  })

  function update(key, value) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function submit(e) {
    e.preventDefault()
    if (!form.title.trim()) return
    onCreate({
      ...form,
      title: form.title.trim(),
      milestones: form.milestones
        .split(',')
        .map((label) => label.trim())
        .filter(Boolean)
        .map((label) => ({ label, done: false })),
    })
  }

  return (
    <Modal title="Nova meta" subtitle="Cadastre um objetivo do seu plano pessoal ou financeiro." onClose={onClose}>
      <form onSubmit={submit} className="space-y-4">
        <label className="block">
          <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Título</span>
          <input
            value={form.title}
            onChange={(e) => update('title', e.target.value)}
            placeholder="Ex.: Faturar R$ 25.000 no trimestre"
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
              <option value="pessoal">Pessoal</option>
              <option value="financeira">Financeira</option>
            </select>
          </label>

          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Prazo</span>
            <input
              value={form.deadline}
              onChange={(e) => update('deadline', e.target.value)}
              placeholder="Ex.: Dez 2026"
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Valor/etapa atual</span>
            <input
              type="number"
              min="0"
              value={form.current}
              onChange={(e) => update('current', e.target.value)}
              placeholder="Opcional"
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>

          <label className="block">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Meta final</span>
            <input
              type="number"
              min="0"
              value={form.target}
              onChange={(e) => update('target', e.target.value)}
              placeholder="Opcional"
              className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue"
            />
          </label>
        </div>

        <label className="block">
          <span className="text-xs font-semibold uppercase tracking-wide text-neutral-500">Milestones</span>
          <textarea
            value={form.milestones}
            onChange={(e) => update('milestones', e.target.value)}
            rows={3}
            placeholder="Separe por vírgula. Ex.: Contratar contador, Fechar 3 clientes, Bater meta"
            className="mt-1.5 w-full text-sm px-3 py-2 border border-neutral-200 dark:border-neutral-700 rounded-lg bg-transparent focus:outline-none focus:border-brand-blue resize-none"
          />
        </label>

        <div className="flex items-center justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="px-4 py-2 text-sm border border-neutral-200 dark:border-neutral-700 rounded-lg">
            Cancelar
          </button>
          <button type="submit" className="px-4 py-2 text-sm font-medium bg-brand-blue text-white rounded-lg hover:bg-blue-700">
            Salvar meta
          </button>
        </div>
      </form>
    </Modal>
  )
}
